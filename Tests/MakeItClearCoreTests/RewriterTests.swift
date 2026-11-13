import Testing
@testable import MakeItClearCore

@Test func emptyInputIsNotRewritable() {
    #expect(RewriteInput.isRewritable("") == false)
    #expect(RewriteInput.isRewritable("   \n\t ") == false)
    #expect(RewriteInput.isRewritable("hi") == true)
}

@Test func cleanTrimsAndStripsWrappingQuotes() {
    #expect(RewriteOutput.clean("  \"Hello.\"  ") == "Hello.")
    #expect(RewriteOutput.clean("“Hi there.”") == "Hi there.")
    #expect(RewriteOutput.clean("Hello.") == "Hello.")
}

@Test func cleanStripsPreamble() {
    #expect(RewriteOutput.clean("Here is the rewritten text:\nHello.") == "Hello.")
    #expect(RewriteOutput.clean("Here's a clearer version:\n\n“Hi there.”") == "Hi there.")
}

@Test func cleanKeepsInnerQuotesAndMultipleParagraphs() {
    #expect(RewriteOutput.clean("He said \"no\".") == "He said \"no\".")
    #expect(RewriteOutput.clean("First line.\n\nSecond line.") == "First line.\n\nSecond line.")
}

@Test func findsDoubleNegatives() {
    #expect(RewriteOutput.doubleNegatives(in: "Nobody didn’t tell me.") == ["Nobody didn’t"])
    #expect(RewriteOutput.doubleNegatives(in: "nobody did not listen") == ["nobody did not"])
    #expect(RewriteOutput.doubleNegatives(in: "No one doesn't care.") == ["No one doesn't"])
    #expect(RewriteOutput.doubleNegatives(in: "He didn't understand nothing.") == ["didn't understand nothing"])
    #expect(RewriteOutput.doubleNegatives(in: "I can't see nobody") == ["can't see nobody"])
}

@Test func ignoresCorrectNegatives() {
    #expect(RewriteOutput.doubleNegatives(in: "Nobody listened to my idea.").isEmpty)
    #expect(RewriteOutput.doubleNegatives(in: "He didn't understand anything.").isEmpty)
    #expect(RewriteOutput.doubleNegatives(in: "My manager never answers my emails.").isEmpty)
    #expect(RewriteOutput.doubleNegatives(in: "I knew nothing, and I didn't ask.").isEmpty)
}

@Test func promptContainsText() {
    #expect(RewritePrompt.prompt(for: "i want go home").contains("i want go home"))
    #expect(!RewritePrompt.instructions.isEmpty)
}

@Test func errorsHaveMessages() {
    #expect(!RewriteError.tooLong.message.isEmpty)
    #expect(!RewriteError.refused.message.isEmpty)
    #expect(RewriteError.unavailable("x").message == "x")
}
