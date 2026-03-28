import XCTest
@testable import Wisp

final class MicrophoneEnumerationTests: XCTestCase {

    func testEnumerationReturnsArray() {
        // May be empty in a headless CI environment — that is valid.
        let devices = MicrophoneList.enumerateInputDevices()
        XCTAssertNotNil(devices)
    }

    func testDevicesHaveNonEmptyUIDs() {
        let devices = MicrophoneList.enumerateInputDevices()
        for device in devices {
            XCTAssertFalse(device.uid.isEmpty, "Device UID must not be empty")
        }
    }

    func testDevicesHaveNonEmptyDisplayNames() {
        let devices = MicrophoneList.enumerateInputDevices()
        for device in devices {
            XCTAssertFalse(device.displayName.isEmpty, "Device display name must not be empty")
        }
    }

    func testAtMostOneDeviceIsDefault() {
        let devices = MicrophoneList.enumerateInputDevices()
        let defaultCount = devices.filter { $0.isDefault }.count
        XCTAssertLessThanOrEqual(defaultCount, 1, "At most one device can be the system default")
    }

    func testMicrophoneDeviceIdentityByUID() {
        let a = MicrophoneDevice(uid: "test-uid", displayName: "Device A", isDefault: false)
        let b = MicrophoneDevice(uid: "test-uid", displayName: "Device B", isDefault: true)
        XCTAssertEqual(a, b, "Devices with equal UIDs are the same physical device")
    }

    func testMicrophoneDeviceIDIsUID() {
        let device = MicrophoneDevice(uid: "my-uid", displayName: "My Mic", isDefault: false)
        XCTAssertEqual(device.id, "my-uid")
    }

    @MainActor
    func testMicrophoneListInitPopulatesDevices() {
        let list = MicrophoneList()
        XCTAssertNotNil(list.devices)
    }

    @MainActor
    func testRefreshDoesNotCrash() {
        let list = MicrophoneList()
        list.refresh()
        XCTAssertNotNil(list.devices)
    }
}
