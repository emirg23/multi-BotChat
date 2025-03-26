
import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Multi_Bot_ChatApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var dataStore: UserDataStore = UserDataStore(user: User(chats: UserDataStore().loadChats(), email: nil))
    @State var loading = true

    var body: some Scene {
        WindowGroup {
            if Auth.auth().currentUser != nil {
                if loading {
                    ProgressView()
                        .onAppear() {
                            dataStore.user.email = Auth.auth().currentUser!.email!.lowercased()
                            print("initing")
                            dataStore.initFirebaseUser() { _ in
                                print("inited")
                                loading = false
                            }
                        }
                } else {
                    Chats(dataStore: dataStore)
                }
            } else {
                Chats(dataStore: dataStore)
            }
        }
    }
}
