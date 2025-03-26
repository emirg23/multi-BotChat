
import SwiftUI

struct BotChat: View {
    @ObservedObject var botChatVM: BotChatViewModel
    @ObservedObject var messageAreaVM: MessageAreaViewModel
    @ObservedObject var dataStore: UserDataStore
    
    init(botChatVM: BotChatViewModel, messageAreaVM: MessageAreaViewModel, dataStore: UserDataStore) {
        self.botChatVM = botChatVM
        self.messageAreaVM = messageAreaVM
        self.dataStore = dataStore
        
        UIBarButtonItem.appearance().tintColor = .reversePrimary
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(botChatVM.bot.darkColor)
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                botChatVM.bot.darkColor
                VStack(spacing: 0){
                    MessageArea(messageAreaVM: messageAreaVM, dataStore: dataStore, botChatVM: botChatVM)
                    
                    textField()
                        .onChange(of: botChatVM.text) { _ in
                            botChatVM.updateTextHeight()
                        }
                }
                
                
                RightTabView(botChatVM: botChatVM, messageAreaVM: messageAreaVM, dataStore: dataStore)
            }
            .background(botChatVM.bot.lightColor)
        }
        .onDisappear() {
            messageAreaVM.selectedChatId = nil
        }
        .toolbar() {
            ToolbarItem(placement: .principal) {
                Text(botChatVM.bot.promptName == "" ? "\(botChatVM.bot.name)" : "\(botChatVM.bot.name) • \(botChatVM.bot.promptName)")
                    .padding(.horizontal)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    botChatVM.rightTabPresent = true
                } label: {
                    botChatVM.bot.logo(size: 30)
                        .background(botChatVM.bot.lightColor)
                        .cornerRadius(25)
                }
            } 
        }
        .toolbarTitleDisplayMode(.inline)
    }
    
    func textField() -> some View {
        VStack {
            TextField("Ask something to \(botChatVM.bot.name)", text: $botChatVM.text, axis: .vertical)
                .font(.system(size: 18))
                .foregroundStyle(.primary.opacity(0.75))
                .frame(height: botChatVM.textHeight)
                .padding(.horizontal)
                .onChange(of: botChatVM.text) { _ in
                    botChatVM.updateTextHeight()
                }
                .submitLabel(.send)
                .onChange(of: botChatVM.text) { newValue in
                    guard let newValueLastChar = newValue.last else { return }
                    if newValueLastChar == "\n" {
                        botChatVM.text.removeLast()
                        botChatVM.closeKeyboard()
                        if !botChatVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !messageAreaVM.botAnswering && !messageAreaVM.botGenerating {
                            botChatVM.sendMessage()
                        }
                    }
                }
            
            HStack {
                
                Spacer()
                
                sendMessageButton()
            }
            .padding(.horizontal)
            .padding(.bottom, 25)
        }
        .background(botChatVM.bot.lightColor)
        .cornerRadius(20, [.topLeft, .topRight])
    }
    
    func sendMessageButton() -> some View {
        Button {
            botChatVM.sendMessage()
        } label: {
            Image(systemName: "arrow.right")
                .font(.system(size: 17, weight: .bold))
                .rotationEffect(Angle(degrees: -90))
                .foregroundStyle(.black)
                .padding(15)
        }
        .frame(width: 40, height: 40)
        .background(.white)
        .disabled(botChatVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || messageAreaVM.botAnswering || messageAreaVM.botGenerating)
        .opacity(botChatVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || messageAreaVM.botAnswering || messageAreaVM.botGenerating ? 0.5 : 1)
        .cornerRadius(20)
        .padding(.bottom, 5)
        .animation(.easeInOut(duration: 0.2), value: botChatVM.text)
    }
}

#Preview {
    var dataStore = UserDataStore(user: User(chats: []), registerOrLoginPresent: true)
    var messageAreaVM = MessageAreaViewModel(dataStore: dataStore)
    BotChat(botChatVM: BotChatViewModel(dataStore: dataStore, messageAreaVM: messageAreaVM, bot: Bot.chatGPT), messageAreaVM: messageAreaVM, dataStore: dataStore)
}
