//
//  QSAppleNotesNote.m
//  Apple Notes plugin for Quicksilver
//

#import "QSAppleNotesNote.h"

static const CGFloat kQSAppleNotesMaxRecencyBoost = 0.10;
static const NSTimeInterval kQSAppleNotesRecencyHalfLife = 30 * 24 * 60 * 60;

@implementation QSAppleNotesNote

- (Class)getRanker {
    return [QSAppleNotesRanker class];
}

@end

@implementation QSAppleNotesRanker {
    QSDefaultObjectRanker *_defaultRanker;
    CGFloat _boost;
}

- (id)initWithObject:(QSBasicObject *)object {
    if (self = [super init]) {
        _defaultRanker = [[QSDefaultObjectRanker alloc] initWithObject:object];

        NSNumber *modified = [(QSObject *)object objectForMeta:kQSAppleNotesModifiedMeta];
        if (modified) {
            NSTimeInterval age = MAX(0, [[NSDate date] timeIntervalSince1970] - [modified doubleValue]);
            _boost = kQSAppleNotesMaxRecencyBoost * pow(0.5, age / kQSAppleNotesRecencyHalfLife);
        }
    }
    return self;
}

- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString *)anAbbreviation options:(NSDictionary *)options {
    QSRankedObject *ranked = [_defaultRanker rankedObject:object forAbbreviation:anAbbreviation options:options];
    if (ranked && [ranked score] > 0) {
        [ranked setScore:[ranked score] * (1 + _boost)];
    }
    return ranked;
}

- (NSString *)matchedStringForAbbreviation:(NSString *)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context {
    return [_defaultRanker matchedStringForAbbreviation:anAbbreviation hitmask:hitmask inContext:context];
}

@end
