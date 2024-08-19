import SwiftUI

struct ContentView: View {
    @State private var score = 0
    @State private var timeLeft = 30
    @State private var molePosition = Int.random(in: 0..<9)
    @State private var lastMolePosition: Int?
    @State private var gameTimer: Timer?
    @State private var moleTimer: Timer?
    @State private var isGameOver = false
    
    // 定义固定网格布局
    let columns = [
        GridItem(.fixed(80)),
        GridItem(.fixed(80)),
        GridItem(.fixed(80))
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Score: \(score)")
                    .font(.largeTitle)
                Spacer()
                Text("Time: \(timeLeft)")
                    .font(.largeTitle)
            }
            .padding()

            // 使用 LazyVGrid 确保网格布局稳定
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<9, id: \.self) { index in
                    Button(action: {
                        if index == molePosition {
                            score += 1
                            molePosition = -1 // 打中后隐藏地鼠
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                updateMolePosition() // 更新地鼠位置
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                            
                            // 确保地鼠只在固定位置显示
                            if index == molePosition {
                                Text("🐹")
                                    .font(.largeTitle)
                            }
                        }
                    }
                }
            }
            .padding()
            .disabled(isGameOver) // 游戏结束后禁用按钮
            
            Spacer()

            if isGameOver {
                VStack {
                    Text("Game Over!")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()

                    Button("Play Again") {
                        resetGame()
                    }
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear(perform: startGame)
    }

    func startGame() {
        resetTimers()
        score = 0
        timeLeft = 30
        molePosition = Int.random(in: 0..<9)
        lastMolePosition = nil // 初始化时没有上一个位置
        isGameOver = false
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                gameOver()
            }
        }

        moleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isGameOver {
                updateMolePosition()
            }
        }
    }

    func resetGame() {
        // 重新开始游戏时，确保按钮能够显示
        startGame()
    }
    
    func resetTimers() {
        gameTimer?.invalidate()
        moleTimer?.invalidate()
    }

    func gameOver() {
        resetTimers()
        isGameOver = true
    }

    func updateMolePosition() {
        var newPosition: Int
        repeat {
            newPosition = Int.random(in: 0..<9)
        } while newPosition == molePosition
        molePosition = newPosition
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@main
struct WhackAMoleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
