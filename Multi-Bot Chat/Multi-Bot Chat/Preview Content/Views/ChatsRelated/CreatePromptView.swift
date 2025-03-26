

import SwiftUI

struct CreatePromptView: View {
    @ObservedObject var dataStore: UserDataStore
    @Binding var creatingNewPrompt: Bot?
    @State var isVisible = false
    @State var items: [String] = [""]
    @State var promptNameInput = ""
    
    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.75)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.creatingNewPrompt = nil
                        }
                    }
                
                if let creatingNewPrompt = creatingNewPrompt {
                    createTable()
                }
            }
        }
        .onChange(of: creatingNewPrompt) {
            items = [""]
            promptNameInput = ""
            withAnimation(.easeInOut(duration: 0.2)) {
                isVisible = creatingNewPrompt != nil
            }
        }
    }
    
    func createTable() -> some View {
        let bot = creatingNewPrompt!
         
        var canSubmit: Bool {
            promptNameInput.count > 0 && promptNameInput.count < 16 && !items.map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).contains("") &&
            !Bot.allBots.map( {[$0.name, $0.promptName.trimmingCharacters(in: .whitespacesAndNewlines)]} ).contains([bot.name, promptNameInput.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
        
        return VStack(spacing: 0) {
            HStack {
                bot.logo(size: 45)
                Text("Prompt for \(bot.name)")
                    .foregroundStyle(.reversePrimary.opacity(0.5))
                Spacer()
            }
            .opacity(0.5)
            .padding(.leading)
            .padding(.top)

            promptNameEnter()

            bot.lightColor
                .frame(height: 1)
            
            ScrollView {
                Spacer()
                    .frame(height: 10)
                ForEach(items.indices, id: \.self) { index in
                    promptEduItem(index: index)
                }
            }

            
            bot.lightColor
                .frame(height: 1)
                .padding(.bottom)
            
            Button {
                let newBot = Bot(name: bot.name, promptName: promptNameInput.trimmingCharacters(in: .whitespacesAndNewlines), prompt: items)
                withAnimation(.easeInOut(duration: 0.2)) {
                    dataStore.objectWillChange.send()
                    Bot.allBots.append(newBot)
                    creatingNewPrompt = nil
                    dataStore.saveUser()
                }
            } label: {
                Text("Add Prompt")
            }
            .padding(10)
            .foregroundStyle(.reversePrimary)
            .background(bot.lightColor)
            .cornerRadius(10)
            .padding(.bottom)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
            .animation(.easeInOut(duration: 0.25), value: canSubmit)
        }
        .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.7)
        .background(
            ZStack {
                Color.backgroundCl
                bot.lightColor.opacity(0.25)
            }
        )
        .cornerRadius(10)
    }
    
    func promptEduItem(index: Int) -> some View {
        HStack {
            Circle()
                .frame(width: 5)
                .foregroundStyle(.reversePrimary.opacity(0.25))

            TextField("A sentence for prompt", text: $items[index])
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if index == 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        items.append("")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .foregroundStyle(.green)
            } else {
                Button {
                    DispatchQueue.main.async {
                        items.remove(at: index)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
    }
    
    func promptNameEnter() -> some View {
        VStack {
            HStack {
                Text("Name")
                Spacer()
            }
            .padding(.horizontal)
            
            TextField("Maximum 15 chars", text: $promptNameInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.trailing, 100)
                .onChange(of: promptNameInput) { newValue in
                    if newValue.count > 15 {
                        promptNameInput = String(newValue.prefix(15))
                    }
                }
        }
        .padding(.vertical, 10)

    }
}

#Preview {
    CreatePromptView(dataStore: UserDataStore(user: User(chats: [])), creatingNewPrompt: .constant(nil))
}

