# Make It Clear — Design

## Why
The user has clear ideas but struggles to express them correctly in written English. They want to paste text and get back a clear, correct version — with zero friction.

## Goals
- Paste English text → one click → clear, correct English out.
- Fix spelling and grammar, and make unclear sentences clear while keeping the original meaning.
- Free, no account, no API key.

## Non-goals
- No translation, no other languages.
- No history, accounts, settings screens, or style presets.
- No system-wide integration (menu bar, services, hotkeys) in v1.

## Anti-goals (failure even if it "works")
- Changing what the user meant.
- Adding ideas, facts, or fluff the user didn't write.
- Anything that makes it more than paste → click → copy.

## Approaches considered
1. **Apple's on-device AI (Foundation Models framework)** — free, offline, private, no setup beyond Apple Intelligence being on. Weaker than large cloud models on very messy text. **Chosen.**
2. Ollama + open model — free and offline, but an extra install, multi-GB download, and slow on 8 GB RAM.
3. Apple spell checker only — free, but can't fix unclear ideas, which is the core problem. Rejected.
(Claude API rejected by the user: paid.)

## Design
- Native macOS app, Swift + SwiftUI, single window.
- Layout: input text box (top), **Make it clear** button (⌘↩), output text box (bottom, selectable) with a **Copy** button.
- On click: send the text to Apple's on-device language model with instructions: *fix spelling and grammar, make it clear and natural, keep the original meaning and the writer's voice, don't add new information, return only the rewritten text.*
- While working: button shows a spinner and is disabled.
- If Apple Intelligence is off or unavailable: show one plain message explaining how to turn it on (System Settings → Apple Intelligence & Siri).

## Calls made by Claude (correct if wrong)
- Rewrite level: fix mistakes **and** clarify sentences, but keep meaning and voice (middle ground between "fix only" and "rewrite freely").
- Output shows only the final text (no diff / explanation of changes).
- Built as an Xcode project in this repo; target: this Mac (Apple silicon, macOS 27).

## Left to the builder
- Exact prompt wording, window size, fonts, app icon.
