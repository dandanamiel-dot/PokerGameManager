
import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var avatar: String // SF Symbol name
    var createdAt: Date
    var groupId: String
    
    @Relationship(deleteRule: .cascade, inverse: \PlayerSession.player)
    var sessions: [PlayerSession] = []
    
    init(name: String, avatar: String = "person.crop.circle.fill", groupId: String = "local") {
        self.id = UUID()
        self.name = name
        self.avatar = avatar
        self.createdAt = Date()
        self.groupId = groupId
    }
}
