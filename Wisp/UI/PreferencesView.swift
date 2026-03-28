import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {

    let preferences: PreferencesStore
    let microphoneList: MicrophoneList

    @State private var promptDraft: String = ""
    @State private var promptError: String? = nil

    var body: some View {
        Form {
            shortcutSection
            microphoneSection
            promptSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 360)
        .onAppear {
            promptDraft = preferences.cleanupPrompt
        }
    }

    // MARK: - Sections

    private var shortcutSection: some View {
        Section("Recording Shortcut") {
            LabeledContent("Toggle Dictation") {
                KeyboardShortcuts.Recorder(for: .toggleDictation)
            }
        }
    }

    private var microphoneSection: some View {
        Section("Input Microphone") {
            if microphoneList.devices.isEmpty {
                Text("No microphones detected")
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    "Microphone",
                    selection: Binding(
                        get: { preferences.selectedMicrophoneUID },
                        set: { preferences.setMicrophoneUID($0) }
                    )
                ) {
                    Text("System Default").tag(String?.none)
                    ForEach(microphoneList.devices) { device in
                        Text(device.displayName).tag(String?.some(device.uid))
                    }
                }
            }
        }
    }

    private var promptSection: some View {
        Section("Transcription Cleanup Prompt") {
            TextEditor(text: $promptDraft)
                .frame(minHeight: 120)
                .font(.body)
                .onChange(of: promptDraft) { _, newValue in
                    if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        promptError = nil
                    }
                }
                .onSubmit { commitPrompt() }

            if let error = promptError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()
                Button("Reset to Default") {
                    preferences.resetCleanupPrompt()
                    promptDraft = preferences.cleanupPrompt
                    promptError = nil
                }
                .buttonStyle(.link)
            }

            Button("Save Prompt") {
                commitPrompt()
            }
            .disabled(promptDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Actions

    private func commitPrompt() {
        do {
            try preferences.setCleanupPrompt(promptDraft)
            promptError = nil
        } catch PreferencesError.emptyPrompt {
            promptError = "Prompt cannot be empty. Enter text or reset to default."
            promptDraft = preferences.cleanupPrompt
        } catch {}
    }
}
