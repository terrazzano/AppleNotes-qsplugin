//
//  QSAppleNotesActions.h
//  Apple Notes plugin for Quicksilver
//

#import "QSAppleNotes.h"

@interface QSAppleNotesActions : QSActionProvider

/** Opens each selected note in its own Notes window (the default action). */
- (QSObject *)openNote:(QSObject *)dObject;

/** Selects the note in the main Notes window. */
- (QSObject *)showNote:(QSObject *)dObject;

/** Selects the folder in the main Notes window. */
- (QSObject *)showFolder:(QSObject *)dObject;

@end
