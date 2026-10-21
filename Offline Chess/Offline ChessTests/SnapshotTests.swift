import XCTest
import SnapshottingTests

class SnapshotTests: SnapshotTest {
    override class func snapshotPreviews() -> [String]? {
        return nil // nil = auto-discover every #Preview in the app target
    }
}
