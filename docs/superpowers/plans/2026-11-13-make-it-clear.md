# Make It Clear Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One-window macOS app: paste English text → "Make it clear" → corrected, clearer text → Copy.

**Architecture:** Swift Package with a testable core library (`MakeItClearCore`: input checks, prompt, output cleanup, rewriter protocol + Apple Foundation Models implementation) and a SwiftUI executable (`MakeItClear`). A shell script wraps the release binary into `Make It Clear.app`.

**Tech Stack:** Swift 6, SwiftUI, FoundationModels (on-device), Swift Testing, SwiftPM.

**Spec:** `docs/superpowers/specs/2026-11-13-make-it-clear-design.md`

## Global Constraints
- Free: only Apple's on-device model (FoundationModels). No network, no API keys.
- English only. No history, accounts, settings.
- Must keep the user's meaning and voice; must not add new information.
- Target: macOS 26+ on Apple silicon.

## Review Focus
- Empty / whitespace-only input → button disabled; nothing sent.
- Apple Intelligence off or model not ready → plain message with how to turn it on.
- Very long text exceeding the model's context → friendly "text too long, try a shorter part" message.
- Model wraps the answer in quotes or a preamble ("Here is the rewritten text:") → stripped.
- Model refuses (guardrail) or other error → friendly message, app stays usable.

---

### Task 1: Core logic

**Files:**
- Create: `Package.swift`, `Sources/MakeItClearCore/Rewriter.swift`, `Tests/MakeItClearCoreTests/RewriterTests.swift`

**Interfaces — Produces:**
- `enum RewriteInput { static func isRewritable(_ text: String) -> Bool }`
- `enum RewritePrompt { static let instructions: String; static func prompt(for text: String) -> String }`
- `enum RewriteOutput { static func clean(_ raw: String) -> String }` — trims whitespace, strips a leading "Here is/Here's ...:" line, strips one pair of wrapping straight/curly quotes.
- `protocol TextRewriting: Sendable { func rewrite(_ text: String) async throws -> String }`
- `enum RewriteError: Error, Equatable { case unavailable(String), tooLong, refused, failed(String) }` with `var message: String`.
- `struct AppleRewriter: TextRewriting` — `static func availabilityProblem() -> String?` (nil when ready); `rewrite` uses `LanguageModelSession(instructions:)`, maps context-window errors → `.tooLong`, guardrail/refusal → `.refused`.

- [ ] Tests: `isRewritable("")`, `("   \n")` false, `("hi")` true; `clean("  \"Hello.\"  ") == "Hello."`; `clean("Here is the rewritten text:\nHello.") == "Hello."`; `clean("Here's a clearer version:\n\n“Hi there.”") == "Hi there."`; `clean("Hello.") == "Hello."`; `prompt(for:)` contains the text; `RewriteError.tooLong.message` non-empty.
- [ ] Run `swift test` → fails; implement; `swift test` → passes.

### Task 2: App window

**Files:** Create `Sources/MakeItClear/MakeItClearApp.swift`, `Sources/MakeItClear/ContentView.swift`

- Input `TextEditor`, button **Make it clear** (⌘↩, disabled when not rewritable or busy, spinner while busy), output `TextEditor` (editable/selectable), **Copy** button (NSPasteboard). Availability problem shown as a banner. Errors shown inline under the button.
- [ ] `swift build` succeeds.

### Task 3: Package & try

**Files:** Create `scripts/build-app.sh`, `.gitignore`, `README.md`

- Script: `swift build -c release`, assemble `build/Make It Clear.app` (Info.plist, bundle id `local.makeitclear`, LSMinimumSystemVersion 26.0), ad-hoc codesign.
- [ ] Run script, launch app, rewrite a sample sentence, confirm output.
- [ ] Commit.
