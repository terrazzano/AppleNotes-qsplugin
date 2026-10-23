// Prints every folder in Notes with the title, id and modification date of
// each note in it, as JSON. Note bodies are never read.
//
//   osascript -l JavaScript FetchNotes.js

function folderPath(folder) {
    let path = folder.name();
    try {
        let parent = folder.container();
        while (parent && parent.class() === 'folder') {
            path = parent.name() + ' / ' + path;
            parent = parent.container();
        }
    } catch (e) {
        // Top-level folders have an account as container; nothing to add.
    }
    return path;
}

function run() {
    const Notes = Application('com.apple.Notes');
    const accounts = Notes.accounts();
    const folders = [];

    for (const account of accounts) {
        const accountName = account.name();
        for (const folder of account.folders()) {
            const notes = folder.notes;
            const names = notes.name();
            const ids = notes.id();
            const modified = notes.modificationDate();
            folders.push({
                account: accountName,
                name: folder.name(),
                path: folderPath(folder),
                id: folder.id(),
                notes: names.map((name, i) => ({
                    name: name,
                    id: ids[i],
                    modified: modified[i].getTime() / 1000,
                })),
            });
        }
    }

    return JSON.stringify({accountCount: accounts.length, folders: folders});
}
