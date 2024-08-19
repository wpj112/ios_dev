import SwiftUI

struct ContentView: View {
    @State private var moles: [[Bool]] = Array(repeating: Array(repeating: false, count: 3), count: 3)
    @State private var score: Int = 0
    @State private var showPlayAgain: Bool = false
    @State private var timer: Timer?
    @State private var gameTimer: Timer?
    @State private var remainingTime: Int = 30 // 游戏时间，单位为秒
    @State private var lastMoleIndex: Int? = nil // 记录上一次的地鼠位置索引
    
    let gridSize = 3
    let moleAppearTime = 1.0 // 每秒出现一个地鼠
    let moleVisibleTime = 0.8 // 每个地鼠可见时间
    
    var body: some View {
        VStack {
            Text("Score: \(score)")
                .font(.largeTitle)
                .padding()
            
            Text("Time: \(remainingTime) seconds")
                .font(.title)
                .padding()
            
            GridStack(rows: gridSize, columns: gridSize) { row, col in
                Button(action: {
                    if moles[row][col] {
                        score += 1
                        moles[row][col] = false
                    }
                }) {
                    Image(systemName: moles[row][col] ? "star.fill" : "star") // 使用 SF Symbols
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .disabled(moles[row][col] == false)
            }
            .padding()
            
            if showPlayAgain {
                Button(action: resetGame) {
                    Text("Play Again")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear(perform: startGame)
    }
    
    func startGame() {
        score = 0
        remainingTime = 30
        showPlayAgain = false
        lastMoleIndex = nil
        startMoleTimer()
        startGameTimer()
    }
    
    func startMoleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: moleAppearTime, repeats: true) { _ in
            showRandomMole()
        }
    }
    
    func startGameTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                endGame()
            }
        }
    }
    
    func showRandomMole() {
        var newMoles = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        
        // 生成不重复的位置索引
        var randomIndex: Int
        repeat {
            randomIndex = Int.random(in: 0..<(gridSize * gridSize))
        } while randomIndex == lastMoleIndex
        
        lastMoleIndex = randomIndex
        let row = randomIndex / gridSize
        let col = randomIndex % gridSize
        newMoles[row][col] = true
        
        moles = newMoles
        
        DispatchQueue.main.asyncAfter(deadline: .now() + moleVisibleTime) {
            moles = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        }
    }
    
    func endGame() {
        timer?.invalidate()
        gameTimer?.invalidate()
        showPlayAgain = true
    }
    
    func resetGame() {
        startGame()
    }
}

struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let content: (Int, Int) -> Content
    
    init(rows: Int, columns: Int, @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.content = content
    }
    
    var body: some View {
        VStack {
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<columns, id: \.self) { column in
                        content(row, column)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
