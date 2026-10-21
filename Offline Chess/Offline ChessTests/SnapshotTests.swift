import XCTest
import SnapshottingTests
import ChessKit

class SnapshotTests: SnapshotTest {
    override class func setUp() {
        super.setUp()

        // ChessKit's `Attacks` cache populates its lookup tables on first
        // `Board()` init; its writes are lock-protected but its reads
        // aren't, so constructing the first `Board()` here (single-threaded,
        // before any previews render) avoids a data race when the preview
        // harness renders multiple #Previews — several of which construct
        // their own `Board()`/`ChessGame()` — concurrently.
        _ = Board()
    }

    override class func snapshotPreviews() -> [String]? {
        return nil // nil = auto-discover every #Preview in the app target
    }
}
