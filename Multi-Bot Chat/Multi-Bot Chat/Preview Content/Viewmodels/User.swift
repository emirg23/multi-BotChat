

import Foundation


class User: ObservableObject {
    @Published var chats: [Chat]
    @Published var email: String?
    init(chats: [Chat], email: String? = nil) {
        self.chats = chats
        self.email = email
    }
    
    static var userDef = User(chats: [])
    
}
 
