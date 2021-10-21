import XCTest
@testable import KeePassKit
@testable import Passs

class MockedPasteboard: Pasteboard {
    var value: String?
}

class PasteboardManagerTests: XCTestCase {

    func testCopy() {
        let pasteboard = MockedPasteboard()
        let pasteboardManager = PasteboardManagerImp(
            pasteboard: pasteboard
        )

        pasteboardManager.copy(password: "test")
        XCTAssertEqual(pasteboard.value, "test")
    }

    func testAutoClear() {

    }

}
