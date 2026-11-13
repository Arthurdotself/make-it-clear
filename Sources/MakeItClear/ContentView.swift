import AppKit
import MakeItClearCore
import SwiftUI

struct ContentView: View {
    @State private var text = ""
    @State private var isWorking = false
    @State private var copied = false
    @State private var lastResult = ""
    @State private var errorMessage: String?
    @State private var availabilityProblem = AppleRewriter.availabilityProblem()
    @FocusState private var editorFocused: Bool

    private let rewriter: TextRewriting = AppleRewriter()

    var body: some View {
        VStack(spacing: 10) {
            header

            if let message = availabilityProblem ?? errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(availabilityProblem != nil ? .orange : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            editor

            Button(action: makeItClear) {
                HStack(spacing: 6) {
                    if isWorking {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: copied ? "checkmark" : "sparkles")
                            .contentTransition(.symbolEffect(.replace))
                    }
                    Text(buttonTitle)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!RewriteInput.isRewritable(text) || isWorking)
        }
        .padding(12)
        .frame(width: 300)
        .onAppear { editorFocused = true }
        .onChange(of: text) { if text != lastResult { copied = false } }
        .animation(.smooth(duration: 0.25), value: copied)
        .animation(.smooth(duration: 0.25), value: isWorking)
    }

    private var header: some View {
        HStack {
            Label("Make It Clear", systemImage: "text.badge.checkmark")
                .font(.headline)
                .labelStyle(.titleAndIcon)
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .help("Quit Make It Clear")
        }
    }

    private var editor: some View {
        TextEditor(text: $text)
            .font(.body)
            .scrollContentBackground(.hidden)
            .focused($editorFocused)
            .padding(10)
            .frame(height: 130)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste your text, then press Enter")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }
            .opacity(isWorking ? 0.5 : 1)
            .disabled(isWorking)
            // Enter = fix & copy. Shift+Enter = new line.
            .onKeyPress(.return, phases: .down) { press in
                if press.modifiers.contains(.shift) { return .ignored }
                makeItClear()
                return .handled
            }
    }

    private var buttonTitle: String {
        if isWorking { return "Working…" }
        if copied { return "Copied" }
        return "Make it clear & copy"
    }

    private func makeItClear() {
        guard RewriteInput.isRewritable(text), !isWorking else { return }
        let input = text
        isWorking = true
        errorMessage = nil
        Task {
            do {
                let result = try await rewriter.rewrite(input)
                lastResult = result
                text = result
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result, forType: .string)
                copied = true
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
}
