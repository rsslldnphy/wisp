import AppKit
import SwiftUI

struct LogView: View {

    let entries: [TranscriptionLogEntry]

    static let timestampFormat: Date.FormatStyle = .dateTime
        .month(.abbreviated)
        .day()
        .hour()
        .minute()

    var body: some View {
        if entries.isEmpty {
            Text("No transcriptions yet.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(entries) { entry in
                LogEntryRow(entry: entry)
            }
        }
    }
}

private struct LogEntryRow: View {

    let entry: TranscriptionLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.timestamp, format: LogView.timestampFormat)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.text)
                    .font(.body)
                    .textSelection(.enabled)
                if !entry.wasPasted {
                    Text("not pasted")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
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
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        .listRowSeparator(.hidden)
    }
}
