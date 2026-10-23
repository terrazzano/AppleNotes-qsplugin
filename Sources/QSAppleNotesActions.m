//
//  QSAppleNotesActions.m
//  Apple Notes plugin for Quicksilver
//

#import "QSAppleNotesActions.h"
#import "QSAppleNotesLibrary.h"

@implementation QSAppleNotesActions

- (QSObject *)openNote:(QSObject *)dObject {
    for (QSObject *note in [dObject splitObjects]) {
        [[QSAppleNotesLibrary sharedLibrary] showItemWithID:[note objectForType:kQSAppleNotesNoteType] isFolder:NO separately:YES];
    }
    return nil;
}

- (QSObject *)showNote:(QSObject *)dObject {
    // The main window shows one note at a time, so only the first one counts.
    QSObject *note = [[dObject splitObjects] firstObject];
    [[QSAppleNotesLibrary sharedLibrary] showItemWithID:[note objectForType:kQSAppleNotesNoteType] isFolder:NO separately:NO];
    return nil;
}

- (QSObject *)showFolder:(QSObject *)dObject {
    QSObject *folder = [[dObject splitObjects] firstObject];
    [[QSAppleNotesLibrary sharedLibrary] showItemWithID:[folder objectForType:kQSAppleNotesFolderType] isFolder:YES separately:NO];
    return nil;
}

@end
