//
//  GameScene.swift
//  BewareTheWerewolf
//
//  Created by Luis Gonzalez on 7/24/18.
//  Copyright © 2018 Luis Gonzalez. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // Playground
    var playground = SKSpriteNode()
    var upperBound = CGFloat(0.0)
    var lowerBound = CGFloat(0.0)
    var moon = Moon(x: 0, y: 0)
    
    var player = Player(midX: 0, midY: 0, scene: nil)
    var knights: [SKSpriteNode] = []
    
    // Physics
    struct PhysicsCategory {
        static let none     : UInt32    = 0
        static let all      : UInt32    = UInt32.max
        static let player   : UInt32    = 0b0001        // 1
        static let edge     : UInt32    = 0b0010        // 2
    }
    
    var lastTouch: CGPoint? = nil
    var moveToTouch: CGPoint? = nil
    var touchTimer: Int = 0
    
    var attackTimer: TimeInterval = 0
    private var lastUpdateTime : TimeInterval = 0
    
    override init(size: CGSize) {
        super.init(size: size)
        
        //Setup the playground
        if (UIScreen.main.nativeBounds.height == 2436) {
            playground = SKSpriteNode(texture: SKTexture(imageNamed: "playgroundX"))
            upperBound = CGFloat(455.0)
            lowerBound = CGFloat(135.0)
        } else {
            playground = SKSpriteNode(texture: SKTexture(imageNamed: "playground"))
            upperBound = CGFloat(367.0)
            lowerBound = CGFloat(115.0)
        }
        
        playground.texture?.filteringMode = SKTextureFilteringMode.nearest
        playground.position = CGPoint(x: frame.midX, y: frame.midY)
        playground.zPosition = -1.0
        addChild(playground)
        
        moon = Moon(x: frame.midX, y: frame.height)
        addChild(moon.sprite)
        
        player = Player(midX: frame.midX, midY: frame.midY, scene: self)
        addChild(player.sprite)
        
        setUpPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        isPaused = false
        // This func is called when the scene is first presented
        lastUpdateTime = 0
        physicsWorld.contactDelegate = self
        
        
        //Setup the knights
        for child in self.children {
            if child.name == "knight" {
                if let child = child as? SKSpriteNode {
                    child.texture?.filteringMode = SKTextureFilteringMode.nearest
//                    child.setScale(5.0)
                    knights.append(child)
                }
            }
        }
        
       
    }
    
    func setUpPhysics() {
        player.sprite.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.sprite.physicsBody?.contactTestBitMask =  PhysicsCategory.edge
        player.sprite.physicsBody?.collisionBitMask =  PhysicsCategory.edge
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: CGPoint(x: 0, y: lowerBound), size: CGSize(width: size.width, height: upperBound - lowerBound )))
        physicsBody?.restitution = 0.0
        
        physicsBody?.categoryBitMask = PhysicsCategory.edge
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.player

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        handleTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        handleTouches(touches)
    }
    
    fileprivate func handleTouches(_ touches: Set<UITouch>) {
        if ((touches.first?.location(in: self).y)! < upperBound && (touches.first?.location(in: self).y)! > lowerBound) {
            print("Touch Inbounds")
            print("touch!", touchTimer)
            
            lastTouch = touches.first?.location(in: self)
            if (moveToTouch == nil) {
                moveToTouch = lastTouch;
            }
            print(lastTouch!, moveToTouch!)
            
            if (touchTimer > 0 && abs(distance(moveToTouch!, lastTouch!)) < 25) {
                // Two or more fast touches close together, so the player should attack not move
                player.shouldAttack = true
                player.shouldMove = false
            } else if (touchTimer <= 0) {
                touchTimer = 15
                // A quick timer to count time between touches
                let wait = SKAction.wait(forDuration: 0.05) //change countdown speed here
                let tick = SKAction.run({
                    [unowned self] in
                    
                    if self.touchTimer > 0{
                        self.touchTimer -= 1
                    }else{
                        self.removeAction(forKey: "touchTimer")
                    }
                })
                let sequence = SKAction.sequence([wait,tick])
                
                run(SKAction.repeatForever(sequence), withKey: "touchTimer")
                
                player.shouldMove = true
            }
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let _ = currentTime - self.lastUpdateTime
        
        player.update(currentTime: currentTime);
        moon.cycle(player: player)
        
        updateEnemies();
        
        self.lastUpdateTime = currentTime
    }
    
    // ==== Enemey Actions ====
    func updateEnemies() {
        //        for knight in knights {
        //            let targetPosition = player.position
        //
        //
        //            updatePosition(for: knight, to: targetPosition!, speed: knightSpeed)
        //        }
    }
    
    // ==== Collissions and physics ====
    func projectileDidCollideWithEnemy(projectile: SKSpriteNode, enemy: SKSpriteNode) {
        projectile.removeFromParent()
        enemy.removeFromParent()
    }
    
    func playerDidHitEdge() {
        print("Hit edge")
        player.shouldAttack = false
    }
    
    func shake() {
        //For testing purposes a hardware shake will turn the player into a werewolf
            player.switchMode()
    }
    
    
    
}

// === Physics ===
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((contact.bodyA.node == player.sprite || contact.bodyB.node == player.sprite)
            && (contact.bodyA.node == self || contact.bodyB.node == self)) {
            playerDidHitEdge()
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.player != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.edge != 0)) {
            if let monster = firstBody.node as? SKSpriteNode,
                let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithEnemy(projectile: projectile, enemy: monster)
            }
        }
    }
    
}
// === End Physics ===


// === Vector+Math Functions ===
func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let xDist = a.x - b.x
    let yDist = a.y - b.y
    return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
}
// === End Vector ===

