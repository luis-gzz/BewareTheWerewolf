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
    
    // Entity values
    let wolfSpeed: CGFloat = 45.0
    let wolfAttackSpeed: CGFloat = 200.0
    let knightSpeed: CGFloat = 15.0
    
    var playerShouldMove = true
    var playerShouldAttack = false
    var currentAction = "standing"
    var player =  SKSpriteNode()
    var wolfAnimationFrames: [SKTexture] = []
    
    var knights: [SKSpriteNode] = []
    
    var lastTouch: CGPoint? = nil
    var moveToTouch: CGPoint? = nil
    var touchTimer: Int = 0
    var attackTimer: TimeInterval = 0
    
    var stoppingPt: CGPoint = CGPoint(x:0, y:0)
    
    private var lastUpdateTime : TimeInterval = 0
    
    override init(size: CGSize) {
        super.init(size: size)
        
        //Setup the playground
        if (UIScreen.main.nativeBounds.height == 2436) {
            playground = SKSpriteNode(imageNamed: "playgroundX")
        } else {
            playground = SKSpriteNode(imageNamed: "playground")
        }
        
        playground.texture?.filteringMode = SKTextureFilteringMode.nearest
        playground.position = CGPoint(x: frame.midX, y: frame.midY)
        playground.zPosition = -1.0
        addChild(playground)
        
        //Set up the player
        buildPlayerAnimation()
        player = SKSpriteNode(texture: wolfAnimationFrames[0])
        player.texture?.filteringMode = SKTextureFilteringMode.nearest
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 23.0, height: 16.0))
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.isDynamic = true
        
        addChild(player)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        // This func is called when the scene is first presented
        self.lastUpdateTime = 0
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
        print("touch!", touchTimer)
        
        lastTouch = touches.first?.location(in: self)
        if (moveToTouch == nil) {
            moveToTouch = lastTouch;
        }
        
        print(lastTouch!, moveToTouch!)
        
        if (touchTimer > 0 && abs(distance(moveToTouch!, lastTouch!)) < 3) {
            // Two or more fast touches close together, so the player should attack not move
            playerShouldAttack = true
            playerShouldMove = false
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
            
            playerShouldMove = true
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
        
        
        self.lastUpdateTime = currentTime
    }
    
    func updatePlayer(currentTime: TimeInterval) {
        print("current action", currentAction)
        
        // MOVING
        if (lastTouch == nil) {
            return
        }
        
        
        let position = player.position
        
        if (shouldPlayerMove(currentPosition: position, touchPosition: lastTouch!)) {
            currentAction = "walking"
            movePlayer(for: player, to: lastTouch!, speed: wolfSpeed)
        } else if (shouldPlayerWalkStop(currentPosition: position, touchPosition: lastTouch!)) {
            player.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            player.removeAllActions()
            player.texture = wolfAnimationFrames[0]
            currentAction = "standing"
        }
    
        // ATTACKING
        if (playerShouldAttack) {
            currentAction = "attacking"
            playerAttack(for: player, to:lastTouch!, currentTime: currentTime, speed: wolfAttackSpeed)
            
        }
        
        if (shouldPlayerAttackStop(currentPosition: position, touchPosition: stoppingPt)) {
            player.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            player.removeAllActions()
            player.texture = wolfAnimationFrames[0]
            attackTimer = 1
        }
    }
    
    fileprivate func playerAttack(for sprite: SKSpriteNode, to target: CGPoint, currentTime: TimeInterval, speed: CGFloat) {
        
        if (attackTimer == 0) {
            attackTimer = currentTime
           
            let currentPosition = sprite.position
            let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
            stoppingPt = CGPoint(x: 65 * cos(angle) + currentPosition.x, y: 65 * sin(angle) + currentPosition.y)
            print(currentPosition, stoppingPt, target)
            let velocityX = speed * cos(angle)
            let velocityY = speed * sin(angle)
            
            let newVelocity = CGVector(dx: velocityX, dy: velocityY)
            sprite.physicsBody?.velocity = newVelocity
            
            print("STARTING TIMER", attackTimer)
            
        } else if (currentTime - attackTimer >= 1) {
                print("ENDING ATTACK")
                attackTimer = 0;
                playerShouldAttack = false
                currentAction = "standing"
            
        }
        
    }
    
    fileprivate func movePlayer(for sprite: SKSpriteNode, to target: CGPoint, speed: CGFloat) {
        let currentPosition = sprite.position
        let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
        
        
        if (target.x < currentPosition.x) {
            let flip = SKAction.scaleX(to: -1, duration: 0)
            sprite.run(flip)
        } else if (target.x >= currentPosition.x) {
            let flip = SKAction.scaleX(to: 1, duration: 0)
            sprite.run(flip)
        }
        
        if sprite.action(forKey: "wolfWalk") == nil {
            // if legs are not moving, start them
            let walk = SKAction.animate(with: Array(wolfAnimationFrames[1...4]), timePerFrame: 0.2)
            sprite.run(SKAction.repeatForever(walk), withKey: "wolfWalk")
        }
        
        
        let velocityX = speed * cos(angle)
        let velocityY = speed * sin(angle)
        
        let newVelocity = CGVector(dx: velocityX, dy: velocityY)
        sprite.physicsBody?.velocity = newVelocity
        
        moveToTouch = target
    }
    
    fileprivate func shouldPlayerMove(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return !playerShouldAttack
            && playerShouldMove
            && abs(distance(currentPosition, touchPosition)) > player.frame.width / 4
    }
    
    fileprivate func shouldPlayerWalkStop(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return currentAction == "walking"
            && (!playerShouldMove
            || abs(distance(currentPosition, touchPosition)) < player.frame.width / 4)
    }
    
    fileprivate func shouldPlayerAttackStop(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return currentAction == "attacking"
            && abs(distance(currentPosition, touchPosition)) < player.frame.width / 7
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
    
    // ==== Functions to build enemy and player animations ====
    func buildPlayerAnimation() {
//        Stand - 0,
//        Walk1 - 1, Walk2 - 2, Walk3 - 3, Walk4 - 4
//        Attack1 - 5, Attack2 - 6, Attack3 - 7
//        Damage1 - 8, Damage2 - 9
//        Die1 - 10, Die2 - 11, Die3 - 12, Die4 - 13, Die5 - 14

        let wolfAnimatedAtlas = SKTextureAtlas(named: "wolf")
        var animFrames: [SKTexture] = []
        
        let numImages = wolfAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let wolfTextureName = "wolf\(i-1)"
            
            animFrames.append(wolfAnimatedAtlas.textureNamed(wolfTextureName))
        }
        wolfAnimationFrames = animFrames
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
        
//        if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
//            (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
//            if let monster = firstBody.node as? SKSpriteNode,
//                let projectile = secondBody.node as? SKSpriteNode {
//                projectileDidCollideWithEnemy(projectile: projectile, enemy: monster)
//            }
//        }
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

