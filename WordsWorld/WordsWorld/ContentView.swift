//
//  ContentView.swift
//  WordsWorld
//
//  Created by 魏平杰 on 2024/8/20.
//
import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var words: [Word] = []
    @State private var wordCounts: [Int] = []
    @State private var wordStatuses: [String] = []
    @State private var selectedWordCount = 10

    var body: some View {
        NavigationStack {
            VStack {
                if !words.isEmpty {
                    Text("Study History")
                        .font(.title)
                        .padding()

                    List {
                        ForEach(words.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text(words[index].word)
                                    .font(.headline)
                                Text("Meaning: \(words[index].meaning)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Studied \(wordCounts[index]) times")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                Text("Status: \(wordStatuses[index])")
                                    .font(.footnote)
                                    .foregroundColor(statusColor(for: wordStatuses[index]))
                            }
                            .padding(.vertical, 5)
                        }
                    }.frame(height: 300)
                        .padding()
                } else {
                    Text("No study history available.")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                }
                

                VStack{
                    Text("How many words do you want to study?")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Picker("Number of words", selection: $selectedWordCount) {
                        ForEach(Array(stride(from: 10, through: min(words.count, 100), by: 10)), id: \.self) { count in
                            Text("\(count) words").tag(count)
                        }
                    }.pickerStyle(MenuPickerStyle())
                }.padding(.top)
                

                NavigationLink(destination: StudyView(words: Array(words.prefix(selectedWordCount)), wordCounts: $wordCounts, wordStatuses: $wordStatuses)) {
                    Text("Start Studying")
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .onAppear {
                loadWords()
            }
        }
    }
    
    func loadWords() {
        if let url = Bundle.main.url(forResource: "words_cet4", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                words = try decoder.decode([Word].self, from: data)
                
                wordCounts = Array(repeating: 0, count: words.count)
                wordStatuses = Array(repeating: "未标记", count: words.count)
            } catch {
                print("Failed to load words: \(error.localizedDescription)")
            }
        }
    }

    func statusColor(for status: String) -> Color {
        switch status {
        case "熟悉":
            return .green
        case "有点生":
            return .yellow
        case "完全忘记":
            return .red
        default:
            return .gray
        }
    }
}

struct StudyView: View {
    let words: [Word]
    @Binding var wordCounts: [Int]
    @Binding var wordStatuses: [String]
    @State private var currentIndex = 0
    @State private var showMeaning = false
    @State private var isStudyCompleted = false
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            Text("Word \(currentIndex + 1) of \(words.count)")
                .font(.headline)
                .padding()

            HStack(alignment: .center) {
                Text(words[currentIndex].word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Button(action: {
                    speak(text: words[currentIndex].word)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title)
                        .foregroundColor(.green)
                        .padding(.leading, 5)
                }
            }
            .padding()

            if showMeaning {
                Text(words[currentIndex].meaning)
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
            }

            Text("You have studied this word \(wordCounts[currentIndex]) times")
                .font(.footnote)
                .foregroundColor(.blue)
                .padding()

            Text("Current Status: \(wordStatuses[currentIndex])")
                .font(.footnote)
                .foregroundColor(statusColor(for: wordStatuses[currentIndex]))
                .padding()

            HStack {
                Button(action: {
                    //updateStatusAndProceed(status: "熟悉")
                    wordCounts[currentIndex] += 1
                    if currentIndex < words.count - 1 {
                        currentIndex += 1
                        showMeaning = false
                    } else {
                        isStudyCompleted = true
                    }
                }) {
                    Text("熟悉")
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    updateStatusAndProceed(status: "有点生")
                    showMeaning = true
                }) {
                    Text("有点生")
                        .font(.title2)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    updateStatusAndProceed(status: "完全忘记")
                    showMeaning = true
                }) {
                    Text("完全忘记")
                        .font(.title2)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()

            Button(action: {
                proceedToNextWordOrFinish()
            }) {
                Text(currentIndex == words.count - 1 ? "Finish" : "Next Word")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationDestination(isPresented: $isStudyCompleted) {
            ContentView()
        }
    }

    func updateStatusAndProceed(status: String) {
        wordStatuses[currentIndex] = status
    }

    func proceedToNextWordOrFinish() {
        wordCounts[currentIndex] += 1
        if currentIndex < words.count - 1 {
            currentIndex += 1
            showMeaning = false
        } else {
            isStudyCompleted = true
        }
    }

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }

    func statusColor(for status: String) -> Color {
        switch status {
        case "熟悉":
            return .green
        case "有点生":
            return .yellow
        case "完全忘记":
            return .red
        default:
            return .gray
        }
    }
}

struct Word: Identifiable, Codable {
    let id = UUID()
    let word: String
    let meaning: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
