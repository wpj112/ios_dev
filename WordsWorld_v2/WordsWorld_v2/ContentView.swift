//
//  ContentView.swift
//  WordsWorld_v2
//
//  Created by 魏平杰 on 2024/8/21.
//

import SwiftUI
import AVFoundation

// 模型结构
struct Word: Identifiable, Codable {
    var id = UUID()  // 自动生成 UUID
    var word: String
    var meaning: String
    var imageName: String
    
    // 自定义 Decodable 实现
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.word = try container.decode(String.self, forKey: .word)
        self.meaning = try container.decode(String.self, forKey: .meaning)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.id = UUID()  // 手动生成 UUID
    }
    
    // 默认初始化
    init(word: String, meaning: String, imageName: String) {
        self.word = word
        self.meaning = meaning
        self.imageName = imageName
    }
}

struct LearningSession: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var wordCount: Int
    var duration: Int
}

// 日期格式扩展
extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

// 主应用视图
struct WordLearningApp: View {
    @State private var words: [Word] = []
    @State private var selectedWordCount = 10
    @State private var learningSessions: [LearningSession] = []

    var body: some View {
        NavigationView {
            VStack {
                // 显示历史记录
                if !learningSessions.isEmpty {
                    Text("History")
                        .font(.title2)
                        .padding()

                    List(learningSessions, id: \.id) { session in
                        VStack(alignment: .leading) {
                            Text("Date: \(session.date, formatter: DateFormatter.shortDate)")
                            Text("Word Count: \(session.wordCount)")
                            Text("Duration: \(session.duration) mins")
                        }
                    }
                    .padding()
                }

                // 设置学习单词数和开始学习按钮
                VStack {
                    Text("Set word count:")
                    Stepper(value: $selectedWordCount, in: 10...50, step: 10) {
                        Text("\(selectedWordCount) words")
                    }
                    .padding()

                    NavigationLink(destination: WordLearningView(selectedWordCount: $selectedWordCount, learningSessions: $learningSessions, words: words)) {
                        Text("Start Learning")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }

                Spacer()
            }
            .onAppear(perform: loadWordsFromFile)
            .navigationTitle("Word Learning")
        }
    }

    // 从文件加载单词
    func loadWordsFromFile() {
        guard let url = Bundle.main.url(forResource: "words_cc", withExtension: "json") else {
            print("Word file not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            words = try JSONDecoder().decode([Word].self, from: data)
            print("Loaded \(words.count) words from file.")
        } catch {
            print("Failed to load words: \(error)")
        }
    }
}

// 学习界面
struct WordLearningView: View {
    @Binding var selectedWordCount: Int
    @Binding var learningSessions: [LearningSession]
    @State private var currentIndex = 0
    @State private var correctAnswer: Word = Word(word: "", meaning: "", imageName: "")
    @State private var options: [Word] = []
    @State private var selectedAnswer: String? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var progress = 0
    @State private var synthesizer = AVSpeechSynthesizer()
    @Environment(\.presentationMode) var presentationMode
    var words: [Word] // 从上一级页面传入的单词数据
    
    var filteredWords: [Word] {
        Array(words.prefix(selectedWordCount))
    }
    
    let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            if currentIndex < filteredWords.count && !filteredWords.isEmpty {
                Text("What is the meaning of: \(filteredWords[currentIndex].word)?")
                    .font(.title)
                    .padding()

                // 朗读图标和单词发音
                Button(action: {
                    speak(word: filteredWords[currentIndex].word)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title)
                        .padding()
                }

                // 选项的九宫格布局
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(options, id: \.id) { option in
                        Button(action: {
                            selectedAnswer = option.meaning
                            checkAnswer()
                        }) {
                            VStack {
                                Image(option.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                Text(option.meaning)
                                    .padding(.top, 5)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .disabled(showResult)
                    }
                }
                .padding()

                // 显示当前进度
                Text("Progress: \(currentIndex + 1)/\(filteredWords.count)")
                    .padding()

                if showResult {
                    Text(isCorrect ? "Correct!" : "Wrong. The correct answer is \(correctAnswer.meaning).")
                        .foregroundColor(isCorrect ? .green : .red)
                        .padding()
                    
                    Button("Next") {
                        goToNextWord()
                    }
                    .padding()
                }
            } else if filteredWords.isEmpty {
                Text("No words available. Please check your word file.")
            } else {
                Text("You've completed all words!")
                Button("Finish") {
                    endSession()
                }
                .padding()
            }
        }
        .onAppear {
            if !filteredWords.isEmpty {
                generateOptions()
                speak(word: filteredWords[currentIndex].word)
            }
        }
        .navigationTitle("Learning")
        .padding()
    }
    
    private func generateOptions() {
        guard currentIndex < filteredWords.count else { return }
        correctAnswer = filteredWords[currentIndex]
        var allOptions = filteredWords
        allOptions.removeAll { $0.id == correctAnswer.id }
        allOptions.shuffle()
        options = Array(allOptions.prefix(3))
        options.append(correctAnswer)
        options.shuffle()
    }
    
    private func checkAnswer() {
        isCorrect = selectedAnswer == correctAnswer.meaning
        showResult = true
    }
    
    private func goToNextWord() {
        selectedAnswer = nil
        showResult = false
        currentIndex += 1
        if currentIndex < filteredWords.count {
            generateOptions()
            speak(word: filteredWords[currentIndex].word)
        }
    }
    
    private func speak(word: String) {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    private func endSession() {
        let session = LearningSession(
            date: Date(),
            wordCount: filteredWords.count,
            duration: currentIndex * 3 // 模拟学习时间
        )
        learningSessions.append(session)
        presentationMode.wrappedValue.dismiss()
    }
}

// 启动应用的入口
@main
struct WordLearningAppMain: App {
    var body: some Scene {
        WindowGroup {
            WordLearningApp()
        }
    }
}
