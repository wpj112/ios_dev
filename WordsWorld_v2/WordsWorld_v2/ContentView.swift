//
//  ContentView.swift
//  WordsWorld_v2
//
//  Created by 魏平杰 on 2024/8/21.
//
//word image from:https://quizlet.com/cn/814267800/raz%E5%8D%95%E8%AF%8D-flash-cards/

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
    @State private var razDictList: [RazDict] = []
    @State private var words: [Word] = []
    @State private var razLevels: [String] = []
    @State private var selectedRazLevel = "raz_C"
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
                    HStack{
                        Text("Set word count:")
                        Stepper(value: $selectedWordCount, in: 10...50, step: 10) {
                            Text("\(selectedWordCount) words")
                        }
                        .padding()
                    }
                    
                    HStack{
                        //选择Level
                        Text("Set raz level:")
                        Picker("Select an level", selection: $selectedRazLevel) {
                            ForEach(razLevels, id: \.self) { level in
                                Text(level)
                            }
                        }
                        .pickerStyle(MenuPickerStyle()) // 可以尝试其他风格如 WheelPickerStyle
                        .padding()
                        .onChange(of: selectedRazLevel) {
                            for dict in razDictList{
                                if(dict.dictName == selectedRazLevel) {
                                    words = dict.wordList
                                }
                            }
                        }
                        //.background(Color(.gray))
                        //.frame(height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    }
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
        guard let url = Bundle.main.url(forResource: "raz_dict", withExtension: "json") else {
            print("Word file not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            razDictList = try JSONDecoder().decode([RazDict].self, from: data)
            //words = razDictList[0].wordList
            
            razLevels.removeAll();
            for dict in razDictList {
                razLevels.append(dict.dictName)
            }
            for dict in razDictList{
                if(dict.dictName == selectedRazLevel) {
                    words = dict.wordList
                }
            }

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
    @State private var tryCount = 0
    @State private var progress = 0
    @State private var synthesizer = AVSpeechSynthesizer()
    @EnvironmentObject var wordManager: WordManager
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
                HStack(alignment: .center, spacing: 20){
                    Text(filteredWords[currentIndex].word)
                        .font(.system(size: 40))
                    // 朗读图标和单词发音
                    Button(action: {
                        speak(word: filteredWords[currentIndex].word)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                    }
                }.frame(alignment: .topLeading)
                    Text("has reviewed count: \(wordManager.getReviewCount(for: filteredWords[currentIndex]))")
                        .font(.title3)
                    
                // 选项的九宫格布局
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(options, id: \.id) { option in
                        Button(action: {
                            selectedAnswer = option.meaning
                            checkAnswer()
                        }) {
                            VStack {
                            //    Image(uiImage: UIImage(named: "Resource/\(option.imageName)"))
                                //if let uiImage = UIImage(named:  "Resources/add.png)") {
                                if let imagePath = Bundle.main.path(forResource: (option.imageName as NSString).deletingPathExtension, ofType: "png"),
                                   let uiImage = UIImage(contentsOfFile: imagePath) {
                                    Image(uiImage: uiImage)
                                        //.resizable()
                                        //.scaledToFit()
                                        .resizable()
                                        .scaledToFill()
                                        .scaleEffect(0.9)
                                        //.frame(height: 120) // 控制图片的总高度
                                        //.clipped() // 裁剪图片
                                        //.frame(height: 120 * 0.75) // 只显示上部 75%
                                        .cornerRadius(5.0)
                                    //                                Text(option.meaning)
                                    //                                    .padding(.top, 5)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(10)
                            .padding(.top, 5)
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 5)
                            .shadow(color: .gray, radius: 6, x: 0, y: 3)
                        }
                        .disabled(showResult)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)


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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        if isCorrect {
            speak(word:"good")
            wordManager.incrementCorrectCount(for: filteredWords[currentIndex])

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                goToNextWord()
            }
        }else {
            tryCount += 1;
            if(tryCount >= 3){
                showResult = true
            }
            speak(word:"try again")
        }

    }
    
    private func goToNextWord() {
        selectedAnswer = nil
        showResult = false
        tryCount = 0
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
        //for voice in AVSpeechSynthesisVoice.speechVoices() {
        //    print(voice.name, voice.identifier)
        //}
        let utterance = AVSpeechUtterance(string: word)
//        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        //com.apple.voice.compact.en-US.Samantha
        //com.apple.speech.synthesis.voice.Zarvox rebote
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha")
        utterance.pitchMultiplier = 1.2;
        utterance.rate = 0.4
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
    private let fileName = "words_record.json"

    init() {
        loadWordsRecordFromFile()
    }

    // 获取文件路径
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func getFilePath() -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }

    // 从文件加载单词数据
    func loadWordsRecordFromFile() {
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
    
    // 更新正确次数并保存
    func incrementCorrectCount(for word: Word) {
        if let index = words.firstIndex(where: { $0.text == word.word }) {
            words[index].corectCount += 1
        }else {
            words.append(WordRecode(text: word.word, reviewCount: 1, corectCount: 1, state: "no"))
        }
        saveWordsToFile()
    }
}

// 主应用界面
struct ContentView: View {
    @StateObject var wordManager = WordManager()

    var body: some View {
        TabView {
            WordLearningApp ()
                .tabItem {
                    Label("Main", systemImage: "book.fill")
                }
            
            RecordsTabView()
                .tabItem {
                    Label("Records", systemImage: "list.bullet")
                }
        }
        .environmentObject(wordManager)
    }
}

// 启动应用的入口
@main
struct WordLearningAppMain: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        WordLearningApp()
//    }
//}

