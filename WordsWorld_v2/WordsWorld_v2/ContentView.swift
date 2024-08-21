//
//  ContentView.swift
//  WordsWorld_v2
//
//  Created by 魏平杰 on 2024/8/21.
//

import SwiftUI
import AVFoundation



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
    @StateObject private var wordManager: WordManager = WordManager()
    @Environment(\.presentationMode) var presentationMode
    var words: [Word] // 从上一级页面传入的单词数据
    
    //var filteredWords: [Word] {
    //    Array(words.prefix(selectedWordCount))
    //}
    @State private var filteredWords: [Word] = []
    
    let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            if currentIndex < filteredWords.count && !filteredWords.isEmpty {
                Text(filteredWords[currentIndex].word)
                    .font(.title)
                    .padding()

                // 朗读图标和单词发音
                Button(action: {
                    speak(word: filteredWords[currentIndex].word)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                }
                Text("has reviewed count: \(wordManager.getReviewCount(for: filteredWords[currentIndex]))")
                    .font(.title3)

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
            filteredWords = selectRandomWords(from: words, count: selectedWordCount)
            if !filteredWords.isEmpty {
                generateOptions()
                speak(word: filteredWords[currentIndex].word)
            }
        }
        .navigationTitle("Learning")
        .padding()
    }
    // 从原始数组中随机选择指定数量的元素
    private func selectRandomWords(from array: [Word], count: Int) -> [Word] {
        let shuffledArray = array.shuffled()
        return Array(shuffledArray.prefix(count))
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
        if isCorrect {
            speak(word:"good")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                goToNextWord()
            }
        }

    }
    
    private func goToNextWord() {
        selectedAnswer = nil
        showResult = false
        //if(currentIndex < filteredWords.count) {
            wordManager.incrementReviewCount(for: filteredWords[currentIndex])
        //}
        currentIndex += 1
        if currentIndex < filteredWords.count {
            generateOptions()
            speak(word: filteredWords[currentIndex].word)
        }
    }
    
    private func speak(word: String) {
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            print(voice.name, voice.identifier)
        }
        let utterance = AVSpeechUtterance(string: word)
//        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.Zarvox")
        utterance.pitchMultiplier = 1.2;
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

class WordManager: ObservableObject {
    @Published var words: [WordRecode] = []
    private let fileName = "words_recode.json"

    init() {
        loadWordsFromFile()
    }

    // 获取文件路径
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func getFilePath() -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }

    // 从文件加载单词数据
    func loadWordsFromFile() {
        let fileURL = getFilePath()
        if let data = try? Data(contentsOf: fileURL) {
            if let decodedWords = try? JSONDecoder().decode([WordRecode].self, from: data) {
                words = decodedWords
                return
            }
        }
        // 如果文件不存在或数据解码失败，加载默认数据
        words = [
            WordRecode(text: "Hello", reviewCount: 0, corectCount: 0, state: "no"),
            WordRecode(text: "World", reviewCount: 0, corectCount: 0, state: "no")
        ]
    }

    // 将单词数据保存到文件
    func saveWordsToFile() {
        let fileURL = getFilePath()
        if let encodedData = try? JSONEncoder().encode(words) {
            try? encodedData.write(to: fileURL)
        }
    }
    
    //获取背诵数次
    func getReviewCount(for word: Word) -> Int{
        if let index = words.firstIndex(where: { $0.text == word.word }) {
            return words[index].reviewCount;
        }else{
            return 0;
        }
    }

    // 更新背诵次数并保存
    func incrementReviewCount(for word: Word) {
        if let index = words.firstIndex(where: { $0.text == word.word }) {
            words[index].reviewCount += 1
        }else {
            words.append(WordRecode(text: word.word, reviewCount: 1, corectCount: 0, state: "no"))
        }
        saveWordsToFile()
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
