# Make It Clear

A tiny macOS menu bar app that turns messy English into clear, correct English.

Paste your text, press **Enter**, and it fixes spelling, grammar, and unclear sentences — while keeping your meaning and your voice.

> **Before:** i want to tell you that the meeting yesterday it was not good becuase nobody dont listen to my idea and i think we loose time.
>
> **After:** I want to tell you that the meeting yesterday was not good because nobody listened to my idea, and I think we lost time.

## Features

- **Lives in the menu bar** — no windows, no Dock icon.
- **One key** — press Enter: the text is fixed in place and copied to your clipboard, ready to paste.
- **Free and private** — uses Apple's on-device AI. No account, no API key, works offline, and your text never leaves your Mac.

## Requirements

- Mac with Apple silicon
- macOS 26 or later
- Apple Intelligence turned on (System Settings → Apple Intelligence & Siri)

## Install

```bash
git clone https://github.com/Arthurdotself/make-it-clear.git
cd make-it-clear
./scripts/build-app.sh
```

Then drag `build/Make It Clear.app` into your Applications folder and open it.

## Usage

1. Click the icon in the menu bar.
2. Paste your text.
3. Press **Enter** (or click **Make it clear & copy**). Use Shift+Enter for a new line.
4. Paste the clear text wherever you need it.

## Development

```bash
swift test                        # fast unit tests
MAKEITCLEAR_LIVE=1 swift test     # also run real text through Apple's AI
```

| Path | What's there |
|---|---|
| `Sources/MakeItClear` | The menu bar app (SwiftUI) |
| `Sources/MakeItClearCore` | Rewriting logic and the AI prompt |
| `Tests` | Unit and live tests |
| `scripts/build-app.sh` | Builds `Make It Clear.app` |
