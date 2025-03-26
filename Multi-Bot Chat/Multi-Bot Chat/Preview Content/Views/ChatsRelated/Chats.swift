
import SwiftUI

struct Chats: View {
    @State var bots: [Bot] = []
    @State var creatingNewPrompt: Bot? = nil
    @State var presentingPrompts: [Bool] = Array(repeating: false, count: Bot.allBots.count)
    @ObservedObject var dataStore: UserDataStore

    @State var launch = true
    init(dataStore: UserDataStore) {
        let copy = dataStore
        if copy.user.email == nil {
            let lastLogBots = UserDataStore().loadBots()
            if !lastLogBots.isEmpty {
              Bot.allBots = lastLogBots
            }
        }
        self.dataStore = copy
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading){
                    TypingEffect(messageAreaVm: MessageAreaViewModel(dataStore: dataStore), botChatVM: BotChatViewModel(dataStore: dataStore, messageAreaVM: MessageAreaViewModel(dataStore: dataStore), bot: Bot.chatGPT), dataStore: dataStore, textsToPossibilities: [
                        "Hey there!",
                        "Welcome!",
                        "Here we go.",
                        "Let's do this.",
                        "Experience all bots!"
                    ], size: 25)
                        .frame(height: 50)
                        .padding(.leading)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 0){
                            ForEach(bots, id: \.self) { bot in
                                ChatPromptsHolder(bot: bot, creatingNewPrompt: $creatingNewPrompt, dataStore: dataStore, presentingPrompts: $presentingPrompts)
                            }
                        }
                    }
                }
                .background(.backgroundCl.opacity(0.85))
                
                CreatePromptView(dataStore: dataStore, creatingNewPrompt: $creatingNewPrompt)
            }
            .onAppear() {
                bots = []
                var seenNames: [String] = []
                for bot in Bot.allBots {
                    if !seenNames.contains(bot.name) {
                        seenNames.append(bot.name)
                        bots.append(bot)
                    }
                }
            }
            .navigationTitle("")
        }
    }
}

#Preview {
    Chats(dataStore: UserDataStore())
}
