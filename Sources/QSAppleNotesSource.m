//
//  QSAppleNotesSource.m
//  Apple Notes plugin for Quicksilver
//

#import "QSAppleNotesSource.h"
#import "QSAppleNotesLibrary.h"
#import "QSAppleNotesNote.h"

@implementation QSAppleNotesSource

#pragma mark Building objects

- (QSObject *)objectForFolder:(NSDictionary *)folder {
    QSObject *object = [QSObject makeObjectWithIdentifier:folder[@"id"]];
    [object setName:folder[@"path"] ?: folder[@"name"]];
    [object setObject:folder[@"id"] forType:kQSAppleNotesFolderType];
    [object setPrimaryType:kQSAppleNotesFolderType];
    NSUInteger count = [folder[@"notes"] count];
    [object setDetails:[NSString stringWithFormat:@"%lu note%@ in Notes", (unsigned long)count, count == 1 ? @"" : @"s"]];
    return object;
}

- (NSArray<QSObject *> *)objectsForNotesInFolder:(NSDictionary *)folder multipleAccounts:(BOOL)multipleAccounts {
    NSString *location = folder[@"path"] ?: folder[@"name"];
    if (multipleAccounts) {
        location = [NSString stringWithFormat:@"%@ — %@", location, folder[@"account"]];
    }

    NSMutableArray *objects = [NSMutableArray array];
    for (NSDictionary *note in folder[@"notes"]) {
        NSString *title = [note[@"name"] length] ? note[@"name"] : @"New Note";
        QSAppleNotesNote *object = [[QSAppleNotesNote alloc] init];
        [object setIdentifier:note[@"id"]];
        [object setName:title];
        [object setObject:note[@"id"] forType:kQSAppleNotesNoteType];
        [object setPrimaryType:kQSAppleNotesNoteType];
        [object setDetails:location];
        [object setObject:note[@"modified"] forMeta:kQSAppleNotesModifiedMeta];
        [object setObject:folder[@"id"] forMeta:kQSAppleNotesFolderIDMeta];
        [objects addObject:object];
    }
    return objects;
}

/** Most recently edited first. */
- (NSArray<QSObject *> *)sortedByModification:(NSArray<QSObject *> *)notes {
    return [notes sortedArrayUsingComparator:^NSComparisonResult(QSObject *a, QSObject *b) {
        return [[b objectForMeta:kQSAppleNotesModifiedMeta] compare:[a objectForMeta:kQSAppleNotesModifiedMeta]];
    }];
}

#pragma mark QSObjectSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
    // Nothing can change while Notes isn't running.
    return !QSAppIsRunning(kQSAppleNotesBundle);
}

- (BOOL)entryCanBeIndexed:(QSCatalogEntry *)theEntry {
    // Quicksilver's own index would bring notes back as plain objects without
    // the recency ranking. The library keeps its own copy on disk instead,
    // so scanning stays cheap and never needs Notes to be running.
    return NO;
}

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry {
    return [QSResourceManager imageNamed:kQSAppleNotesBundle];
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
    QSAppleNotesLibrary *library = [QSAppleNotesLibrary sharedLibrary];
    NSArray<NSDictionary *> *folders = [library folders];
    NSMutableArray *objects = [NSMutableArray array];

    if ([theEntry.identifier hasPrefix:kQSAppleNotesFoldersPreset]) {
        for (NSDictionary *folder in folders) {
            [objects addObject:[self objectForFolder:folder]];
        }
    } else {
        BOOL multipleAccounts = [library hasMultipleAccounts];
        for (NSDictionary *folder in folders) {
            [objects addObjectsFromArray:[self objectsForNotesInFolder:folder multipleAccounts:multipleAccounts]];
        }
    }
    return objects;
}

#pragma mark QSObjectHandler

- (BOOL)objectHasChildren:(QSObject *)object {
    // Notes.app itself (via QSBundleChildHandlers) and folders can be browsed.
    return ![[object primaryType] isEqualToString:kQSAppleNotesNoteType];
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
    QSAppleNotesLibrary *library = [QSAppleNotesLibrary sharedLibrary];
    NSArray<NSDictionary *> *folders = [library folders];
    NSMutableArray *children = [NSMutableArray array];

    if ([[object primaryType] isEqualToString:kQSAppleNotesFolderType]) {
        NSString *folderID = [object objectForType:kQSAppleNotesFolderType];
        for (NSDictionary *folder in folders) {
            if ([folder[@"id"] isEqualToString:folderID]) {
                NSArray *notes = [self objectsForNotesInFolder:folder multipleAccounts:[library hasMultipleAccounts]];
                [children addObjectsFromArray:[self sortedByModification:notes]];
            }
        }
    } else {
        for (NSDictionary *folder in folders) {
            [children addObject:[self objectForFolder:folder]];
        }
    }

    [object setChildren:children];
    return YES;
}

- (void)setQuickIconForObject:(QSObject *)object {
    if ([[object primaryType] isEqualToString:kQSAppleNotesFolderType]) {
        [object setIcon:[NSImage imageNamed:NSImageNameFolder]];
    } else {
        [object setIcon:[QSResourceManager imageNamed:kQSAppleNotesBundle]];
    }
}

@end
