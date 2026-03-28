import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class MicrophoneList {

    private(set) var devices: [MicrophoneDevice] = []
    private var observers: [NSObjectProtocol] = []

    init() {
        refresh()
        observers.append(
            NotificationCenter.default.addObserver(
                forName: AVCaptureDevice.wasConnectedNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: AVCaptureDevice.wasDisconnectedNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        )
    }

    // MARK: - Internal

    func refresh() {
        devices = Self.enumerateInputDevices()
    }

    // MARK: - Device Enumeration

    /// Returns all currently connected audio input devices.
    /// Uses AVFoundation DiscoverySession — safe to call from any context.
    nonisolated static func enumerateInputDevices() -> [MicrophoneDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )
        let defaultUID = AVCaptureDevice.default(for: .audio)?.uniqueID
        return session.devices.map { device in
            MicrophoneDevice(
                uid: device.uniqueID,
                displayName: device.localizedName,
                isDefault: device.uniqueID == defaultUID
            )
        }
    }
}
