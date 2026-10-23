//
//  QSAppleNotesLibrary.h
//  Apple Notes plugin for Quicksilver
//
//  Talks to Notes through the scripts in Resources/ and keeps a copy of the
//  last result on disk, so Quicksilver can list notes without launching Notes.
//

#import "QSAppleNotes.h"

@interface QSAppleNotesLibrary : NSObject

+ (instancetype)sharedLibrary;

/**
 * Folders as dictionaries with keys: account, name, path, id, notes.
 * Each note is a dictionary with keys: name, id, modified.
 *
 * Asks Notes for fresh data when Notes is running (or nothing is cached yet),
 * otherwise returns the copy cached on disk.
 */
- (NSArray<NSDictionary *> *)folders;

/** YES when the notes live in more than one account (iCloud, On My Mac, ...). */
- (BOOL)hasMultipleAccounts;

/** Shows a note or folder in Notes; notes can open in their own window. */
- (void)showItemWithID:(NSString *)itemID isFolder:(BOOL)isFolder separately:(BOOL)separately;

@end
