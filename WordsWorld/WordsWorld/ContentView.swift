//
//  ContentView.swift
//  WordsWorld
//
//  Created by 魏平杰 on 2024/8/20.
//

import SwiftUI
import SwiftData
import AVFoundation


struct ContentView: View {
    // 单词列表
    let words = [
        ("access" ,"v. 获取 n. 接近，入口"),
        ("project" ,"n. 工程；课题、作业"),
        ("intention" ,"n. 打算，意图"),
        ("equivalence" ,"n. 等值，相等"),
        ("negotiate" ,"v. 谈判，协商，交涉"),
        ("disappointing" ,"adj. 令人失望的"),
        ("alternative" ,"n. 代替品"),
        ("generous" ,"adj. 慷慨的"),
        ("biological" ,"adj. 生物的"),
        ("strategy" ,"n. 策略，战略"),
        ("paradox" ,"n. 悖论；自相矛盾"),
        ("primary" ,"adj. 主要的，基本的"),
        ("standpoint" ,"n. 立场"),
        ("grab" ,"v. 抢先，抢占，抢夺"),
        ("crucial" ,"adj. 至关重要的"),
        ("flaw" ,"n. 缺点；错误"),
        ("depressed" ,"adj. 萧条的；沮丧的"),
        ("obstacle" ,"n. 阻碍"),
        ("automatic" ,"adj. 自动的"),
        ("passionate" ,"adj. 热情的"),
        ("gambling" ,"n. 赌博"),
        ("logic" ,"n. 逻辑"),
        ("theory" ,"n. 理论"),
        ("download" ,"v. 下载"),
        ("signal" ,"n. 信号 v. 发信号，打信号；示意"),
        ("authoritative" ,"adj. 权威的"),
        ("smooth" ,"adj. 光滑的"),
        ("institution" ,"n. 社会公共机构；制度；设立，制定"),
        ("vehicle" ,"n. 车辆"),
        ("plague" ,"v. 使困扰"),
        ("psychological" ,"adj. 心理上的"),
        ("shade" ,"n. 阴凉处"),
        ("persistent" ,"adj. 持续的；坚持的"),
        ("voluntary" ,"adj. 自愿的，主动的"),
        ("tolerance" ,"n. 宽容，容忍")
    ]
    
    @State private var currentIndex = 0
    @State private var showMeaning = false
    @State private var wordCounts: [Int] = Array(repeating: 0, count: 5) // 记录每个单词的背诵次数
    @State private var wordStatuses: [String] = Array(repeating: "未标记", count: 5) // 记录每个单词的状态
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            Text(words[currentIndex].0)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Conditionally show the word's meaning
            if showMeaning {
                Text(words[currentIndex].1)
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
            }

            // 显示单词背诵次数和状态
            Text("You have studied this word \(wordCounts[currentIndex]) times")
                .font(.footnote)
                .foregroundColor(.blue)
                .padding()

            
//            Text("Current Status: \(wordStatuses[currentIndex])")
//                .font(.footnote)
//                .foregroundColor(.red)
//                .padding()

            
            HStack {
                Button(action: {
                    // 播放当前单词的朗读
                    speak(text: words[currentIndex].0)
                }) {
                    Text("Read Word")
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    // 显示单词含义
                    showMeaning = true
                }) {
                    Text("Show Meaning")
                        .font(.title2)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()

            HStack {
                Button(action: {
                    wordStatuses[currentIndex] = "熟悉"
                }) {
                    Text("熟悉")
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    wordStatuses[currentIndex] = "有点生"
                }) {
                    Text("有点生")
                        .font(.title2)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    wordStatuses[currentIndex] = "完全忘记"
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
                // 更新索引，循环显示下一个单词，并隐藏含义
                wordCounts[currentIndex] += 1 // 增加当前单词的背诵次数
                currentIndex = (currentIndex + 1) % words.count
                showMeaning = false // 重置以隐藏下一个单词的含义
            }) {
                Text("Next Word")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }

    // 朗读功能
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // 设置语速
        speechSynthesizer.speak(utterance)
    }
}

// 预览代码
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
