//
//  QSAppleNotesLibrary.m
//  Apple Notes plugin for Quicksilver
//

#import "QSAppleNotesLibrary.h"

// Both catalog entries (notes and folders) scan right after each other;
// reuse one fetch for both instead of asking Notes twice.
static const NSTimeInterval kQSAppleNotesFetchReuseInterval = 30.0;

@implementation QSAppleNotesLibrary {
    NSDictionary *_data;          // {accountCount, folders}
    NSDate *_fetchDate;
}

+ (instancetype)sharedLibrary {
    static QSAppleNotesLibrary *library;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        library = [[self alloc] init];
    });
    return library;
}

#pragma mark Data

- (NSArray<NSDictionary *> *)folders {
    return [self data][@"folders"] ?: @[];
}

- (BOOL)hasMultipleAccounts {
    return [[self data][@"accountCount"] integerValue] > 1;
}

- (NSDictionary *)data {
    @synchronized (self) {
        BOOL recentlyFetched = _fetchDate && -[_fetchDate timeIntervalSinceNow] < kQSAppleNotesFetchReuseInterval;
        if (recentlyFetched) {
            return _data;
        }

        if (!_data) {
            _data = [self readCache];
        }

        // Only launch Notes ourselves when there is nothing to show at all.
        if (QSAppIsRunning(kQSAppleNotesBundle) || !_data) {
            NSDictionary *fresh = [self fetchFromNotes];
            if (fresh) {
                _data = fresh;
                _fetchDate = [NSDate date];
                [self writeCache:fresh];
            }
        }
        return _data;
    }
}

- (NSDictionary *)fetchFromNotes {
    NSString *script = [[NSBundle bundleForClass:[self class]] pathForResource:@"FetchNotes" ofType:@"js"];
    NSData *output = [self runScript:script arguments:@[] waitForOutput:YES];
    if (!output) {
        return nil;
    }

    NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:output options:0 error:&error];
    if (![data isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Apple Notes plugin: could not read the list of notes: %@", error);
        return nil;
    }
    return data;
}

#pragma mark Cache

- (NSString *)cachePath {
    return [pCacheLocation stringByAppendingPathComponent:@"AppleNotes.json"];
}

- (NSDictionary *)readCache {
    NSData *json = [NSData dataWithContentsOfFile:[self cachePath]];
    if (!json) {
        return nil;
    }
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    return [data isKindOfClass:[NSDictionary class]] ? data : nil;
}

- (void)writeCache:(NSDictionary *)data {
    NSData *json = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:pCacheLocation withIntermediateDirectories:YES attributes:nil error:nil];
    [json writeToFile:[self cachePath] atomically:YES];
}

#pragma mark Showing items

- (void)showItemWithID:(NSString *)itemID isFolder:(BOOL)isFolder separately:(BOOL)separately {
    if (!itemID) {
        return;
    }
    NSString *script = [[NSBundle bundleForClass:[self class]] pathForResource:@"ShowInNotes" ofType:@"js"];
    NSArray *arguments = @[isFolder ? @"folder" : @"note", itemID, separately ? @"separately" : @"inline"];
    [self runScript:script arguments:arguments waitForOutput:NO];
}

#pragma mark Running scripts

/**
 * Runs a JavaScript for Automation file with osascript. Item IDs are passed
 * as arguments, so nothing has to be escaped into script source.
 */
- (NSData *)runScript:(NSString *)scriptPath arguments:(NSArray<NSString *> *)arguments waitForOutput:(BOOL)wait {
    if (!scriptPath) {
        NSLog(@"Apple Notes plugin: script missing from the plugin bundle");
        return nil;
    }

    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/osascript"];
    task.arguments = [@[@"-l", @"JavaScript", scriptPath] arrayByAddingObjectsFromArray:arguments];
    NSPipe *output = [NSPipe pipe];
    NSPipe *errors = [NSPipe pipe];
    task.standardOutput = output;
    task.standardError = errors;

    if (!wait) {
        task.terminationHandler = ^(NSTask *finished) {
            if (finished.terminationStatus != 0) {
                NSData *message = [errors.fileHandleForReading readDataToEndOfFile];
                NSLog(@"Apple Notes plugin: %@", [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding]);
            }
        };
    }

    NSError *error = nil;
    if (![task launchAndReturnError:&error]) {
        NSLog(@"Apple Notes plugin: could not run osascript: %@", error);
        return nil;
    }
    if (!wait) {
        return nil;
    }

    // Read before waiting, so a large listing can't fill the pipe and stall osascript.
    NSData *result = [output.fileHandleForReading readDataToEndOfFile];
    NSData *message = [errors.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];

    if (task.terminationStatus != 0) {
        // -1743 means macOS has not allowed Quicksilver to control Notes.
        NSLog(@"Apple Notes plugin: Notes did not answer: %@", [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding]);
        return nil;
    }
    return result;
}

@end
