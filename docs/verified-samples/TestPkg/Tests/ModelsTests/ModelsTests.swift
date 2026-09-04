import Testing
import Foundation
import SwiftData
@testable import Models

@Suite struct QueueTests {
    @Test func neverPerformedFirst() throws {
        let container = try Store.inMemory()
        let ctx = ModelContext(container)
        let now = Date()
        ctx.insert(Exercise(name: "b-old", lastPerformed: now.addingTimeInterval(-864000)))
        ctx.insert(Exercise(name: "nil1"))
        ctx.insert(Exercise(name: "a-recent", lastPerformed: now))
        ctx.insert(Exercise(name: "nil2"))
        try ctx.save()
        let fd = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.lastPerformed, order: .forward), SortDescriptor(\.name)])
        let names = try ctx.fetch(fd).map(\.name)
        #expect(names == ["nil1", "nil2", "b-old", "a-recent"])
    }

    @Test func mainContextIsMainActor() {
        #expect(Thread.isMainThread)   // shows @Test runs on main under default MainActor isolation
    }

    @Test func pureHelperOffMain() async {
        let v = await Task.detached { queueSortKey(nil) }.value
        #expect(v == -.infinity)
    }
}
