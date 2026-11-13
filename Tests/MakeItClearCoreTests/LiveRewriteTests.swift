import Foundation
import Testing
@testable import MakeItClearCore

/// Runs real text through Apple's on-device AI. Slow, so only runs with:
///   MAKEITCLEAR_LIVE=1 swift test
private let liveEnabled = ProcessInfo.processInfo.environment["MAKEITCLEAR_LIVE"] == "1"

struct LiveCase: Sendable, CustomStringConvertible {
    let input: String
    let mustContain: [String]
    let mustNotContain: [String]
    var description: String { input }
}

private let cases: [LiveCase] = [
    LiveCase(
        input: "i want to tell you that the meeting yesterday it was not good becuase nobody dont listen to my idea and i think we loose time.",
        mustContain: ["listened"],
        mustNotContain: ["did not listen", "didn't listen", "dont", "loose", "it was not"]),
    LiveCase(
        input: "my manager he dont never answer my emails so i cant finish the report on time",
        mustContain: [],
        mustNotContain: ["dont", "doesn't never", "does not never", "don't never", "he doesn't never", "manager he"]),
    LiveCase(
        input: "nobody didnt tell me about the change in the plan so i was confuse",
        mustContain: ["confused"],
        mustNotContain: ["nobody didn't", "nobody did not", "didnt", "was confuse "]),
    LiveCase(
        input: "the new feature it is more better then the old one and users will like it alot",
        mustContain: ["than"],
        mustNotContain: ["more better", "feature it is", "alot", "better then"]),
    LiveCase(
        input: "yesterday i go to the client and explain him the problem but he dont understand nothing",
        mustContain: ["went"],
        mustNotContain: ["dont", "explain him", "understand nothing", "didn't understand nothing"]),
]

@Test(.enabled(if: liveEnabled), arguments: cases)
func liveRewriteFixesMistakes(_ c: LiveCase) async throws {
    let output = try await AppleRewriter().rewrite(c.input)
    print("IN:  \(c.input)\nOUT: \(output)\n")
    let lower = output.lowercased().replacingOccurrences(of: "’", with: "'")
    for word in c.mustContain {
        #expect(lower.contains(word.lowercased()), "expected \"\(word)\" in: \(output)")
    }
    for word in c.mustNotContain {
        #expect(!lower.contains(word.lowercased()), "unexpected \"\(word)\" in: \(output)")
    }
}

@Test(.enabled(if: liveEnabled))
func liveRewriteIsConsistent() async throws {
    let text = cases[1].input
    let first = try await AppleRewriter().rewrite(text)
    for _ in 0..<3 {
        #expect(try await AppleRewriter().rewrite(text) == first)
    }
}
