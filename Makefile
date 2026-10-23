# Builds the Apple Notes plugin with the Xcode Command Line Tools, against
# the frameworks and headers inside the installed Quicksilver.app.
#
#   make            build build/Apple Notes.qsplugin
#   make install    build, copy into Quicksilver's PlugIns folder, restart Quicksilver
#   make release    build and zip the plugin for a GitHub release
#   make clean

QS_APP     ?= /Applications/Quicksilver.app
FRAMEWORKS := $(QS_APP)/Contents/Frameworks
PLUGINS    := $(HOME)/Library/Application Support/Quicksilver/PlugIns

BUNDLE     := build/Apple Notes.qsplugin
EXECUTABLE := Apple Notes Plugin
INSTALLED  := $(PLUGINS)/com.github.terrazzano.QSAppleNotesPlugin.qsplugin

SOURCES    := $(wildcard Sources/*.m)
CFLAGS     := -fobjc-arc -fmodules -O2 -Wall -Wno-missing-declarations -Wno-deprecated-declarations \
              -mmacosx-version-min=10.15 -arch arm64 -arch x86_64 -F"$(FRAMEWORKS)"
LDFLAGS    := -bundle -bundle_loader "$(QS_APP)/Contents/MacOS/Quicksilver" \
              -framework Cocoa -framework QSCore -framework QSFoundation

VERSION    := $(shell /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
ZIP        := build/AppleNotes-qsplugin-$(VERSION).zip

.PHONY: all install release clean

all:
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS" "$(BUNDLE)/Contents/Resources"
	clang $(CFLAGS) $(LDFLAGS) $(SOURCES) -o "$(BUNDLE)/Contents/MacOS/$(EXECUTABLE)"
	cp Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp Resources/*.js "$(BUNDLE)/Contents/Resources/"
	codesign --force --sign - "$(BUNDLE)"

install: all
	osascript -e 'tell application id "com.blacktree.Quicksilver" to quit' || true
	while pgrep -x Quicksilver >/dev/null; do sleep 0.2; done
	rm -rf "$(INSTALLED)"
	cp -R "$(BUNDLE)" "$(INSTALLED)"
	open -b com.blacktree.Quicksilver

release: all
	rm -f "$(ZIP)"
	ditto -c -k --keepParent "$(BUNDLE)" "$(ZIP)"

clean:
	rm -rf build
