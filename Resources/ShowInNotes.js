// Shows a note or folder in Notes.
//
//   osascript -l JavaScript ShowInNotes.js note|folder <id> [separately]
//
// With "separately", a note opens in its own window instead of being
// selected in the main Notes window.

function run(argv) {
    const [kind, id, mode] = argv;
    const Notes = Application('com.apple.Notes');
    const target = kind === 'folder' ? Notes.folders.byId(id) : Notes.notes.byId(id);

    Notes.activate();
    Notes.show(target, {separately: mode === 'separately'});
}
