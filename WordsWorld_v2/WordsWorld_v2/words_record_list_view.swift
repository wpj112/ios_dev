//
//  words_record_list_view.swift
//  WordsWorld_v2
//
//  Created by 魏平杰 on 2024/8/22.
//

import Foundation
import SwiftUI

// 单词记录界面
struct RecordsTabView: View {
    @EnvironmentObject var wordManager: WordManager

    var body: some View {
        VStack {
            Text("All Word Records")
                .font(.largeTitle)
                .padding()

            List(wordManager.words) { word in
                VStack(alignment: .leading) {
                    Text(word.text)
                        .font(.headline)
                    Text("correct count: \(word.corectCount)")
                        .font(.subheadline)
                    Text("review count: \(word.reviewCount)")
                        .font(.subheadline)
                }
            }
        }
        .padding()
    }
}
