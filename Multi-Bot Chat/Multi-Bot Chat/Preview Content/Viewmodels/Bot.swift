
import Foundation
import SwiftUI

class Bot: ObservableObject, Hashable, Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var promptName: String
    var prompt: [String]
    var darkColor: Color {
        Color(self.name + "Dark")
    }
    var medColor: Color {
        Color(self.name + "Medium")
    }
    var lightColor: Color {
        Color(self.name + "Light")
    }
    
    static func == (lhs: Bot, rhs: Bot) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static var canva = Bot(name: "Canva")
    static var chatGPT = Bot(name: "ChatGPT")
    static var claude = Bot(name: "Claude")
    static var deepSeek = Bot(name: "DeepSeek")
    static var gemini = Bot(name: "Gemini")
    static var llama = Bot(name: "LLaMA")
    
    static var allBots: [Bot] = [ 
        canva, chatGPT, claude, deepSeek, gemini, llama
    ]
    
    init(name: String, promptName: String = "", prompt: [String] = [""]) {
        self.name = name
        self.promptName = promptName
        self.prompt = prompt
    }
    
    func logo(size: CGFloat) -> some View {
        return Image(self.name + "Logo")
            .resizable()
            .padding(2)
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

