import Foundation
import SwiftData

@Model final class Item { var name: String; init(name: String) { self.name = name } }

@ModelActor
actor Background {
    func count() throws -> Int { try modelContext.fetchCount(FetchDescriptor<Item>()) }
    func insertMany(_ n: Int) throws {
        for i in 0..<n { modelContext.insert(Item(name: "i\(i)")) }
        try modelContext.save()
    }
}

@main struct Main {
    static func main() async throws {
        let container = try ModelContainer(for: Item.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let bg = Background(modelContainer: container)
        try await bg.insertMany(5)
        print("count from ModelActor:", try await bg.count())
        let main = ModelContext(container)
        print("count from main ctx:", try main.fetchCount(FetchDescriptor<Item>()))
        let id = try main.fetch(FetchDescriptor<Item>()).first!.persistentModelID
        let name = await bg.nameOf(id)
        print("name via PersistentIdentifier:", name as Any)
    }
}
extension Background {
    func nameOf(_ id: PersistentIdentifier) -> String? { self[id, as: Item.self]?.name }
}
