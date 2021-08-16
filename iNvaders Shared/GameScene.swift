//
//  GameScene.swift
//  GyroBlocks Shared
//
//  Created by Félix Larose-Gervais on 2021-06-14.
//

import SpriteKit

class GameScene: SKScene {
    
    
    fileprivate var spaceship = SKSpriteNode(imageNamed: "spaceship")
    
    private var fireTick = 0
    private var alienTick = 0
    private var alienRate = 50
    private var score = 0
    private var highScore = 0
    private var scoreLabel = SKLabelNode(text: "Score: 0 (Highest: 0)")
    private var pause = false
    
    private let ALIEN_SIZE = 40
    private let SPACESHIP_WIDTH = 40
    private let SPACESHIP_HEIGHT = 50
    private let FIRE_RATE = 10

    private let ALIEN_NAME = "alien"
    private let SPACESHIP_NAME = "spaceship"
    private let SCENE_NAME = "scene"
    private let SHOT_NAME = "shot"
    
    private var level = 1

    
    class func newGameScene() -> GameScene {
        let scene = GameScene(size: .zero)
        scene.scaleMode = .resizeFill
                
        return scene
    }
    
    func spawnAlien() {
        let alien = SKSpriteNode(imageNamed: "alien")
        alien.name = ALIEN_NAME
        alien.position = CGPoint(x: Int.random(in: 0..<Int(self.size.width)), y: Int.random(in: Int(self.size.height-50)..<Int(self.size.height)))
        alien.size = CGSize(width: ALIEN_SIZE, height: ALIEN_SIZE)
        alien.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(ALIEN_SIZE) / 2)
        alien.physicsBody?.affectedByGravity = false
        self.addChild(alien)
    }
    
    func spawnSpaceShip() {
        let size = CGSize(width: SPACESHIP_WIDTH, height: SPACESHIP_HEIGHT)
        self.spaceship.position = CGPoint(x: self.frame.midX, y: 50)
        self.spaceship.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.spaceship.size = size
        self.spaceship.name = SPACESHIP_NAME
        self.spaceship.physicsBody?.affectedByGravity = false
        self.spaceship.physicsBody?.allowsRotation = false
        self.addChild(self.spaceship)
    }
    
    func spawnScoreLabel() {
        self.scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 40)
        self.addChild(self.scoreLabel)
    }
    
    func shoot() {
        let size = CGSize(width: 2, height: 10)
        let shot = SKShapeNode(rectOf: size)
        shot.name = SHOT_NAME
        shot.position = self.spaceship.position
        shot.position.y += CGFloat(SPACESHIP_HEIGHT) / 2
        shot.fillColor = UIColor.red
        shot.physicsBody = SKPhysicsBody(rectangleOf: size)
        shot.physicsBody?.affectedByGravity = false
        self.addChild(shot)
    }
    
    override func didMove(to view: SKView) {
        view.frame = view.frame.inset(by: view.safeAreaInsets)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.name = SCENE_NAME
        
        self.spawnSpaceShip()
        self.spawnScoreLabel()
        self.spawnAlien()
    }
    
    func gameOver() {
        self.pause = true
        let txtGameOver = SKLabelNode(text: "Game Over!")
        txtGameOver.fontColor = SKColor.red
        txtGameOver.fontSize = 64
        txtGameOver.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        txtGameOver.zPosition = 1
        self.addChild(txtGameOver)

        let txtGoAgain = SKLabelNode(text: "Touch to play again")
        txtGoAgain.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 80)
        txtGoAgain.zPosition = 1
        self.addChild(txtGoAgain)
        
        self.highScore = max(self.highScore, self.score)
        self.score = 0
        self.level = 1
        self.alienRate = 50
    }
    
    func playAgain() {
        self.pause = false
        
        self.removeAllChildren()
        
        self.spawnSpaceShip()
        self.spawnScoreLabel()
        self.scoreLabel.text = "Score: \(self.score) (Highest: \(self.highScore))"
    }
    
    func updateNodes() {
        self.fireTick += 1
        if (self.fireTick == FIRE_RATE) {
            self.shoot()
            self.fireTick = 0
        }
        
        if self.score & self.level != 0 {
            self.level <<= 1
            self.alienRate = max(FIRE_RATE, self.alienRate - 5)
        }
        
        self.alienTick += 1
        if (self.alienTick >= self.alienRate) {
            self.spawnAlien()
            self.alienTick = 0
        }
        
        self.enumerateChildNodes(withName: SHOT_NAME) {
            (shot, _) in
            
            shot.position.y += 10
            if let allContactedBodies = shot.physicsBody?.allContactedBodies() {
                for contactedBody in allContactedBodies {
                    switch contactedBody.node?.name {
                    case self.ALIEN_NAME:
                        contactedBody.node?.removeFromParent()
                        self.score += 1
                        self.scoreLabel.text = "Score: \(self.score) (Highest: \(self.highScore))"
                        fallthrough
                    case self.SCENE_NAME:
                        shot.removeFromParent()
                    default:
                        break
                    }
                }
            }
        }
        
        self.enumerateChildNodes(withName: ALIEN_NAME) {
            (alien, _) in
            
            alien.position.y -= 1
            if let allContactedBodies = alien.physicsBody?.allContactedBodies() {
                for contactedBody in allContactedBodies {
                    if contactedBody.node?.name == self.SPACESHIP_NAME {
                        self.gameOver()
                    }
                }
            }
            if alien.position.y < CGFloat(self.ALIEN_SIZE) / 2 {
                self.gameOver()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if (!self.pause) {
            self.updateNodes()
        }
        
    }
}

// Touch-based event handling
extension GameScene {
    
    func moveSpaceShip(touches: Set<UITouch>) {
        for t in touches {
            let pos = t.location(in: self)
            let action = SKAction.move(to: pos, duration: TimeInterval.zero)
            self.spaceship.run(action)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (!self.pause) {
            self.moveSpaceShip(touches: touches)
        } else {
            playAgain()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (!self.pause) {
            self.moveSpaceShip(touches: touches)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
}
