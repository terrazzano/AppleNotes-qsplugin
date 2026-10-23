//
//  QSAppleNotes.h
//  Apple Notes plugin for Quicksilver
//
//  Shared imports and constants.
//

#import <Cocoa/Cocoa.h>
#import <QSCore/QSCore.h>
#import <QSFoundation/QSFoundation.h>

#define kQSAppleNotesBundle         @"com.apple.Notes"

// Object types
#define kQSAppleNotesNoteType       @"com.apple.Notes.note"
#define kQSAppleNotesFolderType     @"com.apple.Notes.folder"

// Catalog preset IDs (see Info.plist)
#define kQSAppleNotesNotesPreset    @"QSPresetAppleNotesNotes"
#define kQSAppleNotesFoldersPreset  @"QSPresetAppleNotesFolders"

// Meta keys stored on note objects
#define kQSAppleNotesModifiedMeta   @"QSAppleNotesModified"   // NSNumber, seconds since 1970
#define kQSAppleNotesFolderIDMeta   @"QSAppleNotesFolderID"   // NSString
