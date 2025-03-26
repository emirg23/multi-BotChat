
import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserDataStore: ObservableObject {
    @Published var user: User
    @Published var registerOrLoginPresent = false
    
    init(user: User = User(chats: []), registerOrLoginPresent: Bool = false) {
        self.user = user
        self.registerOrLoginPresent = registerOrLoginPresent
    }
    
    func saveUser() {
        if self.user.email != nil {
            updateFirebaseUser() { _ in
            }
        } else {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(user.chats) {
                UserDefaults.standard.set(encoded, forKey: "chats")
            }
            
            let encoderTwo = JSONEncoder()
            if let encoded = try? encoderTwo.encode(Bot.allBots) {
                UserDefaults.standard.set(encoded, forKey: "bots")
            }
        }
    }
    
    func loadChats() -> [Chat] {
        if let savedData = UserDefaults.standard.data(forKey: "chats") {
            let decoder = JSONDecoder()
            if let decodedChats = try? decoder.decode([Chat].self, from: savedData) {
                return decodedChats
            }
        }
        return []
    }
    
    func loadBots() -> [Bot] {
        if let savedData = UserDefaults.standard.data(forKey: "bots") {
            let decoder = JSONDecoder()
            if let decodedChats = try? decoder.decode([Bot].self, from: savedData) {
                return decodedChats
            }
        }
        return []
    }
    
    func fetchAllEmails(completion: @escaping ([String]) -> Void)  {
        var emails: [String] = []
        let db = Firestore.firestore().collection("users")
        
        db.getDocuments() { snapshot, error in
            if let error = error {
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            for document in documents {
                emails.append(document.documentID)
            }
            completion(emails)
        }
    }
    
    func updateFirebaseUser(completion: @escaping (Bool) -> Void) {
        guard let email = user.email?.lowercased() else {
            print("User email is nil")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(email)
        let botsRef = userRef.collection("bots")
        let batch = Firestore.firestore().batch()
        let dispatchGroup = DispatchGroup()
        
        botsRef.getDocuments { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                print("Error fetching bots: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            for bot in Bot.allBots {
                let botRef = botsRef.document(bot.promptName == "" ? "\(bot.name)" : "\(bot.name) • \(bot.promptName)")
                let chatsRef = botRef.collection("chats")
                
                if !bot.prompt.map( {$0.trimmingCharacters(in: .whitespacesAndNewlines)}).contains("") {
                    batch.setData([
                        "prompt": bot.prompt
                    ], forDocument: botRef)
                } else {
                    batch.setData([
                        "promptName": ""
                    ], forDocument: botRef)
                }
                
                dispatchGroup.enter()
                chatsRef.getDocuments { snapshot, error in
                    guard let snapshot = snapshot, error == nil else { 
                        print("Error fetching chats: \(error?.localizedDescription ?? "Unknown error")")
                        dispatchGroup.leave()
                        return
                    }
                    
                    for document in snapshot.documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    for chat in self.user.chats.filter( {$0.botName == bot.name && $0.promptName == bot.promptName}) {
                        let chatRef = chatsRef.document(chat.id)
                        
                        batch.setData([
                            "botName": chat.botName,
                            "promptName": chat.promptName,
                            "name": chat.name,
                        ], forDocument: chatRef)
                        
                        let messagesRef = chatRef.collection("messages")
                        
                        dispatchGroup.enter()
                        messagesRef.getDocuments { snapshot, error in
                            guard let snapshot = snapshot, error == nil else {
                                print("Error fetching messages for chat \(chat.id): \(error?.localizedDescription ?? "Unknown error")")
                                dispatchGroup.leave()
                                return
                            }
                            
                            for document in snapshot.documents {
                                batch.deleteDocument(document.reference)
                            }
                             
                            for message in chat.messages {
                                let messageRef = messagesRef.document(message.id)
                                batch.setData([
                                    "sender": message.sender,
                                    "text": message.text,
                                    "date": Timestamp(date: message.date)
                                ], forDocument: messageRef)
                            }
                            
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                batch.commit { error in
                    if let error = error {
                        completion(false)
                        print("Error committing batch: \(error.localizedDescription)")
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func fetchDataFromFirebase(completion: @escaping ([Bot], User) -> Void) {
        guard let email = user.email?.lowercased() else {
            return
        }

        var bots: [Bot] = []
        let userObject = User(chats: [], email: email)

        let botsRef = Firestore.firestore().collection("users").document(email).collection("bots")

        botsRef.getDocuments { snapshot, error in
            guard let botDocuments = snapshot?.documents, error == nil else {
                print("Error fetching bots: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let group = DispatchGroup() 

            for botDocument in botDocuments {
                print(botDocument.documentID)
                let documentName = botDocument.documentID
                let botData = botDocument.data()
                
                var botName = ""
                var promptName = ""

                if documentName.contains("•") {
                    let components = documentName.components(separatedBy: " • ")
                    botName = components[0]
                    promptName = components[1]
                    let prompt = botData["prompt"] as? [String] ?? []
                    let bot = Bot(name: botName, promptName: promptName, prompt: prompt)
                    bots.append(bot)
                } else {
                    botName = documentName
                    promptName = ""
                }



                let chatsRef = botDocument.reference.collection("chats")

                group.enter()
                chatsRef.getDocuments { chatSnapshot, chatError in
                    guard let chatDocuments = chatSnapshot?.documents, chatError == nil else {
                        print("Error fetching chats: \(chatError?.localizedDescription ?? "Unknown error")")
                        group.leave()
                        return
                    }

                    for chatDocument in chatDocuments {
                        print(chatDocument.documentID)
                        let chatData = chatDocument.data()
                        let messagesRef = chatDocument.reference.collection("messages")

                        group.enter()
                        messagesRef.getDocuments { messageSnapshot, messageError in
                            guard let messageDocuments = messageSnapshot?.documents, messageError == nil else {
                                group.leave()
                                return
                            }
                            
                            var messages: [ChatMessage] = []
                            
                            for messageDocument in messageDocuments {
                                let messageData = messageDocument.data()
                                if let timestamp = messageData["date"] as? Timestamp {
                                    let message = ChatMessage(
                                        sender: messageData["sender"] as? String ?? "",
                                        text: messageData["text"] as? String ?? "",
                                        date: timestamp.dateValue()
                                    )
                                    messages.append(message)
                                }
                            }
                            
                            messages.sort(by: { $0.date < $1.date })
                            
                            let chat = Chat(
                                messages: messages,
                                botName: botName,
                                promptName: promptName,
                                name: chatData["name"] as? String ?? ""                            )
                            userObject.chats.append(chat)
                            group.leave()
                        }
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(bots, userObject)
            }
        }
    }
    
    func initFirebaseUser(completion: @escaping (Bool) -> Void) {
        self.fetchDataFromFirebase { (fetchedBots, user) in
            Bot.allBots.append(contentsOf: fetchedBots)
            self.user = user
            self.objectWillChange.send()
            completion(true)
        }
    }

    func logOut() {
        do {
            self.objectWillChange.send()
            try Auth.auth().signOut()
            self.user.email = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func firebaseDataToChats() {
        
    }
    
    func firebaseDataToBots() {
        
    }

    
    func updateUIData() {
        
    }
}
