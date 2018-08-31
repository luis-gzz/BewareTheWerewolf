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
    
    // Entity values
    let wolfSpeed: CGFloat = 45.0
    let wolfAttackSpeed: CGFloat = 175.0
    let knightSpeed: CGFloat = 15.0
    
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
        
        updatePlayer(currentTime: currentTime);
        updateEnemies();
        
        moon.cycle(player: player)
        
        self.lastUpdateTime = currentTime
    }
    
    func updatePlayer(currentTime: TimeInterval) {
        //print("current action", player.currentAction)
        
        // MOVING
        if (lastTouch == nil) {
            return
        }
        
        let position = player.sprite.position
        
        if (shouldPlayerMove(currentPosition: position, touchPosition: lastTouch!)) {
            player.currentAction = "walking"
            movePlayer(for: player.sprite, to: lastTouch!, speed: wolfSpeed)
        } else if (shouldPlayerWalkStop(currentPosition: position, touchPosition: lastTouch!)) {
            player.sprite.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            player.sprite.removeAction(forKey: "playerWalk")
            player.sprite.texture = player.getStandingFrames()
            player.currentAction = "standing"
        }
    
        // ATTACKING
        if (player.shouldAttack) {
            player.currentAction = "attacking"
            playerAttack(for: player.sprite, to:lastTouch!, currentTime: currentTime, speed: wolfAttackSpeed)
            
        }
        
        if (shouldPlayerAttackStop(currentPosition: position, touchPosition: player.stoppingPt)) {
            player.sprite.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            player.sprite.removeAction(forKey: "playerAttack")
            player.sprite.texture = player.getStandingFrames()
            attackTimer = 1
        }
    }
    
    fileprivate func playerAttack(for sprite: SKSpriteNode, to target: CGPoint, currentTime: TimeInterval, speed: CGFloat) {
        
        if (attackTimer == 0) {
            attackTimer = currentTime
           
            let currentPosition = sprite.position
            let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
            player.setStoppingPoint(angle: angle)
            
            let velocityX = speed * cos(angle)
            let velocityY = speed * sin(angle)
            
            let newVelocity = CGVector(dx: velocityX, dy: velocityY)
            sprite.physicsBody?.velocity = newVelocity
        
            let attack = SKAction.animate(with: player.getAttackingFrames(), timePerFrame: 0.15)
            sprite.run(attack, withKey: "playerAttack")
            
            
            
            print("STARTING TIMER", attackTimer)
            
        } else if (currentTime - attackTimer >= 1) {
                print("ENDING ATTACK")
                attackTimer = 0;
                player.shouldAttack = false
                player.currentAction = "standing"
            
        }
        
    }
    
    fileprivate func movePlayer(for sprite: SKSpriteNode, to target: CGPoint, speed: CGFloat) {
        let currentPosition = sprite.position
        let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
        
        
        if (target.x < currentPosition.x) {
            let flip = SKAction.scaleX(to: -abs(player.sprite.xScale), duration: 0)
            sprite.run(flip)
        } else if (target.x >= currentPosition.x) {
            let flip = SKAction.scaleX(to: abs(player.sprite.xScale), duration: 0)
            sprite.run(flip)
        }
        
        if sprite.action(forKey: "playerWalk") == nil {
            // if legs are not moving, start them
            let walk = SKAction.animate(with: player.getWalkingFrames(), timePerFrame: 0.2)
            sprite.run(SKAction.repeatForever(walk), withKey: "playerWalk")
        }
        
        
        let velocityX = speed * cos(angle)
        let velocityY = speed * sin(angle)
        
        let newVelocity = CGVector(dx: velocityX, dy: velocityY)
        sprite.physicsBody?.velocity = newVelocity
        
        moveToTouch = target
    }
    
    fileprivate func shouldPlayerMove(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return player.currentAction != "transforming"
            && !player.shouldAttack
            && player.shouldMove
            && abs(distance(currentPosition, touchPosition)) > player.sprite.frame.width / 4
    }
    
    fileprivate func shouldPlayerWalkStop(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return player.currentAction == "walking"
            && (!player.shouldMove
            || abs(distance(currentPosition, touchPosition)) < player.sprite.frame.width / 4)
    }
    
    fileprivate func shouldPlayerAttackStop(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return player.currentAction == "attacking"
            && (!player.shouldAttack
            || abs(distance(currentPosition, touchPosition)) < player.sprite.frame.width / 4)
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

