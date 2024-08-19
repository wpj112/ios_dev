//
//  ViewController.swift
//  Whack_a_Mole
//
//  Created by 魏平杰 on 2024/8/19.
//

import UIKit

class ViewController: UIViewController {

    var moleButtons: [UIButton] = []
    var scoreLabel: UILabel!
    var timerLabel: UILabel!
    var displayLink: CADisplayLink?
    var moleTimer: Timer?
    var score = 0
    var timeLeft = 30.0 // 游戏时间（秒）
    var startTime: CFTimeInterval?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startGame()
    }
    
    func setupUI() {
        // 创建分数和计时器标签
        scoreLabel = UILabel()
        scoreLabel.text = "Score: 0"
        scoreLabel.font = UIFont.systemFont(ofSize: 24)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)
        
        timerLabel = UILabel()
        timerLabel.text = "Time: 30"
        timerLabel.font = UIFont.systemFont(ofSize: 24)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        
        // 设置标签布局
        NSLayoutConstraint.activate([
            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 创建3x3的按钮网格
        let gridLayout = UIStackView()
        gridLayout.axis = .vertical
        gridLayout.distribution = .fillEqually
        gridLayout.spacing = 10
        
        for _ in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 10
            
            for _ in 0..<3 {
                let button = UIButton(type: .system)
                button.setTitle("", for: .normal)
                button.backgroundColor = .systemGreen
                button.titleLabel?.font = UIFont.systemFont(ofSize: 40)
                button.addTarget(self, action: #selector(moleTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
                moleButtons.append(button)
            }
            gridLayout.addArrangedSubview(rowStack)
        }
        
        view.addSubview(gridLayout)
        gridLayout.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gridLayout.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridLayout.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gridLayout.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            gridLayout.heightAnchor.constraint(equalTo: gridLayout.widthAnchor)
        ])
    }

    func startGame() {
        score = 0
        timeLeft = 30.0
        updateScore()
        updateTime()
        
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateTime))
        displayLink?.add(to: .main, forMode: .default)
        
        moleTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(showMole), userInfo: nil, repeats: true)
    }

    @objc func showMole() {
        // 随机选取一个按钮作为地鼠出现的位置
        moleButtons.forEach { $0.setTitle("", for: .normal) }
        
        let randomIndex = Int.random(in: 0..<moleButtons.count)
        let moleButton = moleButtons[randomIndex]
        moleButton.setTitle("🐹", for: .normal)
    }

    @objc func moleTapped(_ sender: UIButton) {
        if sender.currentTitle == "🐹" {
            score += 1
            updateScore()
            sender.setTitle("", for: .normal)
        }
    }

    @objc func updateTime() {
        guard let startTime = startTime else { return }
        
        let elapsedTime = CACurrentMediaTime() - startTime
        timeLeft = 30.0 - elapsedTime
        if timeLeft > 0 {
            timerLabel.text = String(format: "Time: %.1f", timeLeft)
        } else {
            displayLink?.invalidate()
            moleTimer?.invalidate()
            timerLabel.text = "Time: 0.0"
            showGameOverAlert()
        }
    }

    func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }

    func showGameOverAlert() {
        let alert = UIAlertController(title: "Game Over", message: "Your score is \(score)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: .default, handler: { _ in
            self.startGame()
        }))
        present(alert, animated: true, completion: nil)
    }
}
