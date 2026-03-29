import Foundation
import WhisperKit

final class TranscriptionService: @unchecked Sendable {

    private var whisperKit: WhisperKit?
    private var loadTask: Task<Void, Error>?

    func loadModel() async throws {
        // If already loaded, return immediately
        if whisperKit != nil { return }

        // If load is in progress, await it
        if let existing = loadTask {
            try await existing.value
            return
        }

        // Start loading
        let task = Task {
            print("[Wisp] Downloading/loading WhisperKit model (~500MB first time)...")
            let kit = try await WhisperKit(
                model: "openai_whisper-small",
                verbose: true
            )
            self.whisperKit = kit
            print("[Wisp] WhisperKit model loaded successfully")
        }
        loadTask = task

        do {
            try await task.value
        } catch {
            loadTask = nil
            print("[Wisp] WhisperKit model load failed: \(error)")
            throw TranscriptionError.modelNotLoaded
        }
    }

    func unloadModel() {
        whisperKit = nil
        loadTask = nil
    }

    func transcribe(audioBuffer: Data, wordHints: [String] = []) async throws -> String {
        try await loadModel()

        guard let kit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let floatCount = audioBuffer.count / MemoryLayout<Float>.size
        guard floatCount > 0 else {
            throw TranscriptionError.processingFailed(message: "Empty audio buffer")
        }

        let floatArray: [Float] = audioBuffer.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return [] }
            let pointer = baseAddress.assumingMemoryBound(to: Float.self)
            return Array(UnsafeBufferPointer(start: pointer, count: floatCount))
        }

        do {
            var decodeOptions = DecodingOptions()
            if !wordHints.isEmpty, let tokenizer = kit.tokenizer {
                let hintText = wordHints.joined(separator: ", ")
                decodeOptions.promptTokens = tokenizer.encode(text: hintText)
            }
            let results = try await kit.transcribe(
                audioArray: floatArray,
                decodeOptions: decodeOptions
            )
            let text = results.map(\.text).joined(separator: " ").trimmingCharacters(
                in: .whitespacesAndNewlines)
            return text
        } catch {
            throw TranscriptionError.processingFailed(message: error.localizedDescription)
        }
    }
}
