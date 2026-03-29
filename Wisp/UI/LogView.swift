import AppKit
import SwiftUI

struct LogView: View {

    var logStore: TranscriptionLogStore
    var wordDictionary: WordDictionaryStore

    static let timestampFormat: Date.FormatStyle = .dateTime
        .month(.abbreviated)
        .day()
        .hour()
        .minute()

    var body: some View {
        if logStore.entries.isEmpty {
            Text("No transcriptions yet.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(logStore.entries) { entry in
                LogEntryRow(
                    entry: entry,
                    logStore: logStore,
                    wordDictionary: wordDictionary
                )
            }
        }
    }
}

private struct LogEntryRow: View {

    let entry: TranscriptionLogEntry
    let logStore: TranscriptionLogStore
    let wordDictionary: WordDictionaryStore

    @State private var isEditing: Bool = false
    @State private var editDraft: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.timestamp, format: LogView.timestampFormat)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isEditing {
                    TextEditor(text: $editDraft)
                        .font(.body)
                        .frame(minHeight: 44)
                        .onSubmit { commitEdit() }
                } else {
                    Text(entry.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .onTapGesture(count: 2) { startEditing() }
                }

                if !entry.wasPasted {
                    Text("not pasted")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()

            if isEditing {
                VStack(spacing: 4) {
                    Button("Save") { commitEdit() }
                        .buttonStyle(.borderless)
                        .disabled(editDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Cancel") { cancelEdit() }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } else {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        .listRowSeparator(.hidden)
    }

    // MARK: - Edit actions

    private func startEditing() {
        editDraft = entry.text
        isEditing = true
    }

    private func commitEdit() {
        let trimmed = editDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            cancelEdit()
            return
        }
        let newWords = WordDictionaryStore.extractNewWords(from: entry.text, to: trimmed)
        for word in newWords {
            wordDictionary.add(word)
        }
        logStore.update(id: entry.id, text: trimmed)
        isEditing = false
    }

    private func cancelEdit() {
        editDraft = ""
        isEditing = false
    }
}
