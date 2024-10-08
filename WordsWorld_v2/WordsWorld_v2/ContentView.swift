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
    @State private var selectedWordCount = 20
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
                        Spacer()
                        Stepper(value: $selectedWordCount, in: 20...200, step: 20) {
                            Text("\(selectedWordCount) words")
                        }
                    }.frame(maxWidth: .infinity,maxHeight: 50, alignment: .leading) // 使 HStack 左对齐
                        .padding()
                    
                    HStack{
                        //选择Level
                        Text("Set raz level:")
                        Spacer()
                        Picker("Select an level", selection: $selectedRazLevel) {
                            ForEach(razLevels, id: \.self) { level in
                                Text(level)
                            }
                        }
                        .pickerStyle(MenuPickerStyle()) // 可以尝试其他风格如 WheelPickerStyle
                        .onChange(of: selectedRazLevel) {
                            for dict in razDictList{
                                if(dict.dictName == selectedRazLevel) {
                                    words = dict.wordList
                                }
                            }
                        }
                        //.background(Color(.gray))
                        //.frame(height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    }.frame(maxWidth: .infinity, alignment: .leading) // 使 HStack 左对齐
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

// 自定义形状
struct Top80PercentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let height = rect.height
        let top80Percent = height * 0.75
        
        path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: top80Percent))
        return path
    }
}


// 学习界面
struct WordLearningView: View {
    @Binding var selectedWordCount: Int
    @State private var hasLoaded = false
    @Binding var learningSessions: [LearningSession]
    @State private var currentIndex = 0
    @State private var correctAnswer: Word = Word(word: "", meaning: "", imageName: "")
    @State private var options: [Word] = []
    @State private var selectedAnswer: String? = nil
    @State private var showResult = false
    @State private var showChinese = false
    @State private var isCorrect = false
    @State private var tryCount = 0
    @State private var progress = 0
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var totalCorrectCount : Int = 0
    @State private var totalTryCount : Int = 0
    @State private var showConfirmationDialog = false
    @State private var isButtonDisabled = false
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
//                    Text("has reviewed count: \(wordManager.getReviewCount(for: filteredWords[currentIndex]))")
//                        .font(.title3)
                    
                // 选项的九宫格布局
                LazyVGrid(columns: gridColumns, spacing: 0) {
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
                                        .resizable()
                                        .scaledToFit()
                                        .scaledToFill()
                                        .scaleEffect(0.85)
                                        .clipShape(Top80PercentShape()) // 只显示上半部分
                                        //.frame(alignment: .topLeading) // 控制图片的总高度
                                        .frame(height: 160) // 只显示上部 75%
                             //           .clipped() // 裁剪图片
                                        .cornerRadius(5.0)
//                                    if showChinese {
//                                        Text(option.meaning)
//                                    }
                                }
                            }
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: 160)
                            .cornerRadius(10)
                            .padding(.leading, 5)
                            .shadow(color: .gray, radius: 6, x: 0, y: 3)
                        }
                        .disabled(showResult || isButtonDisabled)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

//                Button(action: {
//                    showChinese.toggle() // 切换文本的显示状态
//                }) {
//                    Text(showChinese ? "hide Chinese" : "Show Chinese")
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }

                // 显示当前进度
                Text("Progress: \(currentIndex + 1)/\(filteredWords.count)")
                    .padding()

                if showResult {
                    Text(isCorrect ? "Correct!" : "Wrong. The correct answer is \(correctAnswer.meaning).")
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    if !isCorrect {
                        Button(action: {
                            goToNextWord()
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "arrowshape.right.fill") // 使用 SF Symbols 中的图标
                            }
                        }.padding(.top,5)
                    }
                }
            } else if filteredWords.isEmpty {
                Text("No words available. Please check your word file.")
            } else {
                Text("You've completed all words!")
                    .frame(alignment: .leading)
                Text("total correct count: \(totalCorrectCount)")
                    .frame(alignment: .leading)
                Text("total try count: \(totalTryCount)")
                    .frame(alignment: .leading)
                Text("total review words: \(selectedWordCount)")
                    .frame(alignment: .leading)
                Button(action:{
                    endSession()
                }) {
                    Text("finish")
                        .font(.title)
                    Image(systemName: "arrow.uturn.backward.square.fill") // 使用 SF Symbols 中的图标
                        .font(.title)
                }
                .padding()
            }
        }
        .onAppear {
            if !hasLoaded {
                filteredWords = selectRandomWords(from: words, count: selectedWordCount)
                if !filteredWords.isEmpty {
                    generateOptions()
                    speak(word: filteredWords[currentIndex].word)
                }
                hasLoaded = true;
            }
        }
        .navigationTitle("Learning")
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationBarBackButtonHidden(true) // 隐藏默认的返回按钮
           .toolbar {
               ToolbarItem(placement: .navigationBarLeading) {
                   Button(action: {
                       showConfirmationDialog = true
                   }) {
                       Image(systemName: "chevron.left")
                       Text("Back")
                   }
               }
           }
           .alert(isPresented: $showConfirmationDialog) {
               Alert(
                   title: Text("Are you sure you want to go back?"),
                   primaryButton: .destructive(Text("Yes")) {
                       presentationMode.wrappedValue.dismiss()
                   },
                   secondaryButton: .cancel()
               )
           }
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
            showResult = true
            wordManager.incrementCorrectCount(for: filteredWords[currentIndex])
            totalCorrectCount += 1;

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                goToNextWord()
            }
        }else {
            wordManager.incrementReviewCount(for: filteredWords[currentIndex])
            tryCount += 1;
            totalTryCount += 1;
            if(tryCount >= 2){
                speak(word:"Ow no")
                showResult = true
            }else {
                speak(word:"try again")
            }
        }

    }
    
    private func goToNextWord() {
        selectedAnswer = nil
        showResult = false
        tryCount = 0
        wordManager.incrementReviewCount(for: filteredWords[currentIndex])
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
    var reviewCount : Int = 0
    var correcCount : Int = 0
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
            WordRecode(text: "Hello", reviewCount: 0, corectCount: 0, state: "no", lastRviewTime: "1970-01-01"),
            WordRecode(text: "World", reviewCount: 0, corectCount: 0, state: "no", lastRviewTime: "1970-01-01")
        ]
        reviewCount = words.count;
    }
    func getReviewCount() -> Int{
        return reviewCount
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 指定日期格式
        let currentDate = Date()
        let dateString = formatter.string(from:currentDate)
        if let index = words.firstIndex(where: { $0.text == word.word }) {
            words[index].reviewCount += 1
        }else {
            words.append(WordRecode(text: word.word, reviewCount: 1, corectCount: 0, state: "no", lastRviewTime: dateString))
        }
        saveWordsToFile()
    }
    
    // 更新正确次数并保存
    func incrementCorrectCount(for word: Word) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 指定日期格式
        let currentDate = Date()
        let dateString = formatter.string(from: currentDate)
        if let index = words.firstIndex(where: { $0.text == word.word }) {
            words[index].corectCount += 1
        }else {
            words.append(WordRecode(text: word.word, reviewCount: 1, corectCount: 1, state: "no", lastRviewTime: dateString))
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

