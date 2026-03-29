import SwiftUI

struct WordDictionaryView: View {

    @Bindable var wordDictionary: WordDictionaryStore

    @State private var newWordDraft: String = ""
    @State private var isAdding: Bool = false
    @State private var editingIndex: Int? = nil
    @State private var editDraft: String = ""

    var body: some View {
        if wordDictionary.words.isEmpty && !isAdding {
            emptyState
        } else {
            wordList
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No words in dictionary")
                .foregroundStyle(.secondary)
            Button("Add Word") { startAdding() }
                .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var wordList: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(Array(wordDictionary.words.enumerated()), id: \.offset) { index, word in
                    wordRow(index: index, word: word)
                }
                .onDelete { offsets in
                    wordDictionary.remove(at: offsets)
                }

                if isAdding {
                    addRow
                }
            }
            .listStyle(.plain)
            .frame(minHeight: 80, maxHeight: 200)

            HStack {
                Spacer()
                Button("Add Word") { startAdding() }
                    .buttonStyle(.link)
                    .disabled(isAdding)
            }
            .padding(.top, 4)
        }
    }

    private func wordRow(index: Int, word: String) -> some View {
        HStack {
            if editingIndex == index {
                TextField("Word", text: $editDraft)
                    .textFieldStyle(.plain)
                    .onSubmit { commitEdit(at: index) }
                Button("Done") { commitEdit(at: index) }
                    .buttonStyle(.borderless)
                    .font(.caption)
                Button("Cancel") { editingIndex = nil }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(word)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Edit") {
                    editDraft = word
                    editingIndex = index
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
    }

    private var addRow: some View {
        HStack {
            TextField("New word\u{2026}", text: $newWordDraft)
                .textFieldStyle(.plain)
                .onSubmit { commitAdd() }
            Button("Add") { commitAdd() }
                .buttonStyle(.borderless)
                .font(.caption)
                .disabled(newWordDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel") { cancelAdding() }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func startAdding() {
        newWordDraft = ""
        isAdding = true
    }

    private func commitAdd() {
        let trimmed = newWordDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        wordDictionary.add(trimmed)
        cancelAdding()
    }

    private func cancelAdding() {
        newWordDraft = ""
        isAdding = false
    }

    private func commitEdit(at index: Int) {
        wordDictionary.update(at: index, word: editDraft)
        editingIndex = nil
    }
}
