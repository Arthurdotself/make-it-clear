import Foundation
import FoundationModels

public enum RewriteInput {
    public static func isRewritable(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public enum RewritePrompt {
    public static let instructions = """
    You are an English writing assistant. The user will give you text written by someone \
    who has clear ideas but struggles to express them in English.
    Rewrite the text so it is correct and clear:
    - Fix all spelling, grammar, and punctuation mistakes.
    - Make unclear or awkward sentences clear and natural.
    - Keep the original meaning and the writer's voice and tone.
    - Do not add new ideas, facts, or details. Do not remove ideas.
    - Keep roughly the same length and paragraph structure.
    Common mistakes to fix:
    - Double negatives: "nobody dont listen" means "nobody listened", never "nobody did not listen".
    - Repeated subjects: "the meeting it was" becomes "the meeting was".
    - Wrong verb tense for past events: "yesterday we go" becomes "yesterday we went".
    - Confused words: loose/lose, then/than, your/you're, its/it's, their/there.
    - Missing articles and capital letters: "i want go" becomes "I want to go".
    Before answering, check every sentence once more for any remaining double negative or grammar mistake.

    Example:
    Text: the meeting yesterday it was not good becuase nobody dont listen to my idea
    Rewritten: Yesterday's meeting didn't go well because nobody listened to my idea.

    Reply with only the rewritten text. No introduction, no explanation, no quotes.
    """

    /// Always pick the most likely answer so the same text gives the same result.
    static let options = GenerationOptions(samplingMode: .greedy)

    /// Used only when a double negative is detected in the rewrite.
    public static let fixInstructions = """
    You fix double negatives in English text. Words like "nobody", "no one", "nothing", \
    and "never" already mean "not", so they must not be used with "didn't", "don't", or "not".
    - "Nobody didn't tell me" becomes "Nobody told me".
    - "He didn't understand nothing" becomes "He didn't understand anything".
    Change only the phrases you are told about. Keep everything else exactly the same.
    Reply with only the full corrected text. No introduction, no explanation, no quotes.
    """

    public static func fixPrompt(for text: String, phrases: [String]) -> String {
        let list = phrases.map { "\"\($0)\"" }.joined(separator: ", ")
        return "This text has a double negative: \(list). Fix it.\n\n\(text)"
    }

    public static func prompt(for text: String) -> String {
        "Rewrite this text:\n\n\(text)"
    }
}

public enum RewriteOutput {
    public static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Drop a leading "Here is/Here's ...:" line the model sometimes adds.
        if let firstBreak = text.firstIndex(of: "\n") {
            let firstLine = text[..<firstBreak].lowercased()
            if (firstLine.hasPrefix("here is") || firstLine.hasPrefix("here's") || firstLine.hasPrefix("here’s"))
                && firstLine.hasSuffix(":") {
                text = String(text[firstBreak...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Drop one pair of quotes wrapping the whole answer.
        let pairs: [(Character, Character)] = [("\"", "\""), ("“", "”")]
        for (open, close) in pairs where text.count >= 2 && text.first == open && text.last == close {
            let inner = text.dropFirst().dropLast()
            if !inner.contains(open) && !inner.contains(close) {
                text = String(inner).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            break
        }
        return text
    }

    /// Finds double negatives like "nobody didn't" or "didn't understand nothing".
    /// Returns the matched phrases as they appear in the text.
    public static func doubleNegatives(in text: String) -> [String] {
        let negWord = #"(?:nobody|no one|nothing|never|none)"#
        let negVerb = #"(?:(?:do|does|did|is|was|were|are|ca|could|wo|would|should|have|has|had)n['’]t|(?:do|does|did|can|could|will|would) not|cannot)"#
        let patterns = [
            #"\b\#(negWord) \#(negVerb)\b"#,             // "nobody didn't"
            #"\b\#(negVerb) \w+ \#(negWord)\b"#,         // "didn't understand nothing"
        ]
        var found: [String] = []
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            for match in regex.matches(in: text, range: range) {
                if let r = Range(match.range, in: text) { found.append(String(text[r])) }
            }
        }
        return found
    }
}

public enum RewriteError: Error, Equatable {
    case unavailable(String)
    case tooLong
    case refused
    case failed(String)

    public var message: String {
        switch self {
        case .unavailable(let reason): reason
        case .tooLong: "This text is too long for Apple's on-device AI. Try rewriting a shorter part at a time."
        case .refused: "Apple's AI declined to rewrite this text. Try changing the wording a little."
        case .failed(let detail): "Something went wrong: \(detail)"
        }
    }
}

public protocol TextRewriting: Sendable {
    func rewrite(_ text: String) async throws -> String
}

public struct AppleRewriter: TextRewriting {
    public init() {}

    /// nil when the on-device model is ready to use.
    public static func availabilityProblem() -> String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence is turned off. Turn it on in System Settings → Apple Intelligence & Siri, then reopen this app."
        case .unavailable(.modelNotReady):
            return "Apple's AI model is still downloading or getting ready. Try again in a few minutes."
        case .unavailable(.deviceNotEligible):
            return "This Mac doesn't support Apple Intelligence."
        case .unavailable:
            return "Apple's on-device AI isn't available right now."
        }
    }

    public func rewrite(_ text: String) async throws -> String {
        if let problem = Self.availabilityProblem() {
            throw RewriteError.unavailable(problem)
        }
        do {
            let rewriteSession = LanguageModelSession(instructions: RewritePrompt.instructions)
            var result = RewriteOutput.clean(try await rewriteSession.respond(
                to: RewritePrompt.prompt(for: text), options: RewritePrompt.options).content)

            // The small model sometimes leaves double negatives; point at them and ask again.
            for _ in 0..<2 {
                let phrases = RewriteOutput.doubleNegatives(in: result)
                if phrases.isEmpty { break }
                let fixSession = LanguageModelSession(instructions: RewritePrompt.fixInstructions)
                let fixed = RewriteOutput.clean(try await fixSession.respond(
                    to: RewritePrompt.fixPrompt(for: result, phrases: phrases), options: RewritePrompt.options).content)
                if fixed.isEmpty { break }
                result = fixed
            }
            return result
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize: throw RewriteError.tooLong
            case .guardrailViolation, .refusal: throw RewriteError.refused
            default: throw RewriteError.failed(error.localizedDescription)
            }
        } catch {
            throw RewriteError.failed(error.localizedDescription)
        }
    }
}
