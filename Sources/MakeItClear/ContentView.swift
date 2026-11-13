import AppKit
import MakeItClearCore
import SwiftUI

struct ContentView: View {
    @State private var text = ""
    @State private var original: String?
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var copied = false
    @State private var availabilityProblem = AppleRewriter.availabilityProblem()

    private let rewriter: TextRewriting = AppleRewriter()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let availabilityProblem {
                Label(availabilityProblem, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }

            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Paste your text here…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
                .disabled(isWorking)
                .frame(height: 220)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout)
            }

            HStack(spacing: 8) {
                Button(action: makeItClear) {
                    HStack(spacing: 6) {
                        if isWorking { ProgressView().controlSize(.small) }
                        Text(isWorking ? "Working…" : "Make it clear")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!RewriteInput.isRewritable(text) || isWorking)

                Button(copied ? "Copied!" : "Copy", action: copy)
                    .disabled(text.isEmpty || isWorking)

                if original != nil && !isWorking {
                    Button("Undo", action: undo)
                }

                Spacer()

                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 420)
        .onChange(of: text) { copied = false }
    }

    private func makeItClear() {
        let input = text
        isWorking = true
        errorMessage = nil
        Task {
            do {
                let result = try await rewriter.rewrite(input)
                original = input
                text = result
                availabilityProblem = nil
            } catch let error as RewriteError {
                errorMessage = error.message
                availabilityProblem = AppleRewriter.availabilityProblem()
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }

    private func undo() {
        if let original { text = original }
        original = nil
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
    }
}
