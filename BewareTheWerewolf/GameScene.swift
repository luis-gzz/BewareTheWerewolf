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
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    // Entety values
    let playerSpeed: CGFloat = 150.0
    let knightSpeed: CGFloat = 75.0
    
    var player: SKSpriteNode?
    var knights: [SKSpriteNode] = []
    
    var lastTouch: CGPoint? = nil
    
    private var lastUpdateTime : TimeInterval = 0
    
    override func didMove(to view: SKView) {
        // This func is called when the scene is first presented
        self.lastUpdateTime = 0
        physicsWorld.contactDelegate = self
        
        //Set up the player
        player = childNode(withName: "werewolf") as? SKSpriteNode
        player?.texture?.filteringMode = SKTextureFilteringMode.nearest
        player?.setScale(5.0)
        
        
        //Setup the knights
        for child in self.children {
            if child.name == "knight" {
                if let child = child as? SKSpriteNode {
                    child.texture?.filteringMode = SKTextureFilteringMode.nearest
                    child.setScale(5.0)
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
        lastTouch = touches.first?.location(in: self)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let _ = currentTime - self.lastUpdateTime
        
        updatePlayer();
        updateEnemies();
        
        
        self.lastUpdateTime = currentTime
    }
    
    func updatePlayer() {
        guard let player = player,
              let touch = lastTouch else {
                return
        }
        
        let position = player.position
        
        if (shouldPlayerMove(currentPosition: position, touchPosition: touch)) {
            updatePosition(for: player, to: touch, speed: playerSpeed)
        }
        
    }
    
    
    func updateEnemies() {
        for knight in knights {
            let targetPosition = player?.position
            
            
            updatePosition(for: knight, to: targetPosition!, speed: knightSpeed)
        }
    }
    
    fileprivate func updatePosition(for sprite: SKSpriteNode,
                                    to target: CGPoint,
                                    speed: CGFloat) {
        let currentPosition = sprite.position
        let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
        
        
        if (target.x < currentPosition.x) {
            let flip = SKAction.scaleX(to: -5, duration: 0)
            sprite.run(flip)
        } else if (target.x >= currentPosition.x) {
            let flip = SKAction.scaleX(to: 5, duration: 0)
            sprite.run(flip)
        }
        
        let velocityX = speed * cos(angle)
        let velocityY = speed * sin(angle)
        
        let newVelocity = CGVector(dx: velocityX, dy: velocityY)
        sprite.physicsBody?.velocity = newVelocity
    }
    
    fileprivate func shouldPlayerMove(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        guard let player = player else { return false }
        return abs(currentPosition.x - touchPosition.x) > player.frame.width / 2 ||
            abs(currentPosition.y - touchPosition.y) > player.frame.height / 2
    }
    
    // Custom collision handler
    func projectileDidCollideWithEnemy(projectile: SKSpriteNode, enemy: SKSpriteNode) {
        projectile.removeFromParent()
        enemy.removeFromParent()
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


// === Vector Functions ===
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
// === End Vector ===

