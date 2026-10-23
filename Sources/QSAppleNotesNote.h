//
//  QSAppleNotesNote.h
//  Apple Notes plugin for Quicksilver
//
//  A note in the catalog. Its own class only so it can use a ranker that
//  favours recently edited notes.
//

#import "QSAppleNotes.h"

@interface QSAppleNotesNote : QSObject
@end

/**
 * Ranks like Quicksilver's default ranker, then raises the score of notes
 * edited recently: up to 10% for a note edited today, half that for one
 * edited a month ago, and so on. Notes you open often still win through
 * Quicksilver's own learning (mnemonics).
 *
 * Wraps the default ranker instead of subclassing it: Quicksilver calls the
 * default implementation directly for any QSDefaultObjectRanker subclass.
 */
@interface QSAppleNotesRanker : NSObject <QSObjectRanker>
@end
