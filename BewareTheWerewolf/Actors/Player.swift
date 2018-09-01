//
//  Player.swift
//  BewareTheWerewolf
//
//  Created by Luis Gonzalez on 8/25/18.
//  Copyright © 2018 Luis Gonzalez. All rights reserved.
//
import SpriteKit
import GameplayKit


class Player {
    var sprite = SKSpriteNode();   // this property holds our actual SKSpriteNode
    
    var scenePtr: GameScene?
    
    var wolfAnimationFrames: [SKTexture] = []
    var tobiasAnimationFrames: [SKTexture] = []
    
    var isWere = false
    
    var shouldMove = false
    var shouldAttack = false
    
    var currentAction = "standing"
    var skullCounter = 0
    var stoppingPt: CGPoint = CGPoint(x:0, y:0)
    
    let wolfSpeed: CGFloat = 45.0
    let wolfAttackSpeed: CGFloat = 175.0
    let knightSpeed: CGFloat = 15.0
    
    init(midX: CGFloat, midY: CGFloat, scene: GameScene?) {
        if let sc = scene {
            scenePtr = sc
        }
        
        //Set up the player
        buildPlayerAnimation()
        
        // Do a little switcheroo to get proper scaling
        isWere = true
        sprite = SKSpriteNode(texture: getStandingFrames())
        self.isWere = false
        self.sprite.texture = tobiasAnimationFrames[0]
        self.sprite.texture?.filteringMode = SKTextureFilteringMode.nearest
        self.sprite.setScale(0.85)
        
        sprite.position = CGPoint(x: midX, y: midY)
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10.0, height: 16.0))
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.restitution = 0.0
    }
    
    func update(currentTime: TimeInterval) {
        //print("current action", player.currentAction)
        
        // MOVING
        if (scenePtr?.lastTouch == nil) {
            return
        }
        let lastTouch = scenePtr?.lastTouch
        
        let position = sprite.position
        
        if (shouldPlayerMove(currentPosition: position, touchPosition: lastTouch!)) {
            currentAction = "walking"
            move(for: sprite, to: lastTouch!, speed: wolfSpeed)
        } else if (shouldPlayerStopWalking(currentPosition: position, touchPosition: lastTouch!)) {
            sprite.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            sprite.removeAction(forKey: "playerWalk")
            sprite.texture = getStandingFrames()
            currentAction = "standing"
        }
        
        // ATTACKING
        if (shouldAttack) {
            currentAction = "attacking"
            attack(for: sprite, to:lastTouch!, currentTime: currentTime, speed: wolfAttackSpeed)
        }
        
        if (shouldPlayerStopAttacking(currentPosition: position, touchPosition: stoppingPt)) {
            sprite.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
            sprite.removeAction(forKey: "playerAttack")
            sprite.texture = getStandingFrames()
            scenePtr?.attackTimer = 1
        }
    }
    
    fileprivate func attack(for sprite: SKSpriteNode, to target: CGPoint, currentTime: TimeInterval, speed: CGFloat) {
        if (scenePtr?.attackTimer == 0) {
            scenePtr?.attackTimer = currentTime
            
            let currentPosition = sprite.position
            let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
            setStoppingPoint(angle: angle)
            
            let velocityX = speed * cos(angle)
            let velocityY = speed * sin(angle)
            
            let newVelocity = CGVector(dx: velocityX, dy: velocityY)
            sprite.physicsBody?.velocity = newVelocity
            
            let attack = SKAction.animate(with: getAttackingFrames(), timePerFrame: 0.15)
            sprite.run(attack, withKey: "playerAttack")
            
            
            
            print("STARTING TIMER", scenePtr?.attackTimer ?? 0)
            
        } else if (currentTime - scenePtr!.attackTimer >= 1) {
            print("ENDING ATTACK")
            scenePtr?.attackTimer = 0;
            shouldAttack = false
            currentAction = "standing"
            
        }
        
    }
    
    fileprivate func move(for sprite: SKSpriteNode, to target: CGPoint, speed: CGFloat) {
        let currentPosition = sprite.position
        let angle = CGFloat.pi + atan2(currentPosition.y - target.y, currentPosition.x - target.x)
        
        
        if (target.x < currentPosition.x) {
            let flip = SKAction.scaleX(to: -abs(sprite.xScale), duration: 0)
            sprite.run(flip)
        } else if (target.x >= currentPosition.x) {
            let flip = SKAction.scaleX(to: abs(sprite.xScale), duration: 0)
            sprite.run(flip)
        }
        
        if sprite.action(forKey: "playerWalk") == nil {
            // if legs are not moving, start them
            let walk = SKAction.animate(with: getWalkingFrames(), timePerFrame: 0.2)
            sprite.run(SKAction.repeatForever(walk), withKey: "playerWalk")
        }
        
        
        let velocityX = speed * cos(angle)
        let velocityY = speed * sin(angle)
        
        let newVelocity = CGVector(dx: velocityX, dy: velocityY)
        sprite.physicsBody?.velocity = newVelocity
        
        scenePtr?.moveToTouch = target
    }
    
    fileprivate func shouldPlayerMove(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return currentAction != "transforming"
            && !shouldAttack
            && shouldMove
            && abs(distance(currentPosition, touchPosition)) > sprite.frame.width / 4
    }
    
    fileprivate func shouldPlayerStopWalking(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return currentAction == "walking"
            && (!shouldMove
            || abs(distance(currentPosition, touchPosition)) < sprite.frame.width / 4)
    }
    
    fileprivate func shouldPlayerStopAttacking(currentPosition: CGPoint, touchPosition: CGPoint) -> Bool {
        return currentAction == "attacking"
            && (!shouldAttack
            || abs(distance(currentPosition, touchPosition)) < sprite.frame.width / 4)
    }
    
    func setStoppingPoint(angle: CGFloat) {
        if (isWere) {
            stoppingPt = CGPoint(x: 85 * cos(angle) + sprite.position.x, y: 85 * sin(angle) + sprite.position.y)
            
        } else if (!isWere) {
            stoppingPt = CGPoint(x: 65 * cos(angle) + sprite.position.x, y: 65  * sin(angle) + sprite.position.y)
        }
    }
    
    func switchMode() {
        sprite.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        sprite.removeAction(forKey: "playerWalk")
        sprite.texture = getStandingFrames()
        scenePtr?.attackTimer = 1
        currentAction = "transforming"
        
        if (isWere) {
            let fall = SKAction.animate(with: Array(wolfAnimationFrames[11...14]), timePerFrame: 0.15)
            let revive = SKAction.animate(with: Array(tobiasAnimationFrames[11...14]).reversed(), timePerFrame: 0.15)
            let scale = SKAction.run {
                self.isWere = false
                self.sprite.texture = self.tobiasAnimationFrames[14]
                self.sprite.texture?.filteringMode = SKTextureFilteringMode.nearest
                self.sprite.setScale(0.85)
                print("width", self.sprite.xScale, "heigth", self.sprite.yScale)
            }
            let done = SKAction.run {
                //now scale back to norm size? or do something else
                self.sprite.texture = self.tobiasAnimationFrames[0]
                self.currentAction = "standing"
                self.scenePtr?.attackTimer = 0
            }
            let sequence = SKAction.sequence( [fall , scale, revive , done] )
            sprite.run(sequence , withKey: "toTobias")

        } else if (!isWere) {
            let fall = SKAction.animate(with: Array(tobiasAnimationFrames[11...14]), timePerFrame: 0.15)
            let revive = SKAction.animate(with: Array(wolfAnimationFrames[11...14]).reversed(), timePerFrame: 0.15)
            let scale = SKAction.run {
                self.isWere = true
                self.sprite.texture = self.wolfAnimationFrames[14]
                self.sprite.texture?.filteringMode = SKTextureFilteringMode.nearest
                self.sprite.setScale(1.25)
            }
            let done = SKAction.run {
                //now scale back to norm size? or do something else
                self.sprite.texture = self.wolfAnimationFrames[0]
                self.currentAction = "standing"
                self.scenePtr?.attackTimer = 0
            }
            let seq = SKAction.sequence( [fall , scale, revive , done] )
            sprite.run( seq , withKey: "toWolf")
 
        }
        
    }
    
    func getStandingFrames() -> SKTexture {
        if (isWere) {
            return wolfAnimationFrames[0]
        } else {
            return tobiasAnimationFrames[0]
        }
    }
    
    func getWalkingFrames() -> Array<SKTexture> {
        if (isWere) {
            return Array(wolfAnimationFrames[1...4])
        } else {
            return Array(tobiasAnimationFrames[1...4])
        }
    }
    
    func getAttackingFrames() -> Array<SKTexture> {
        if (isWere) {
            return Array(wolfAnimationFrames[5...7])
        } else {
            return Array(tobiasAnimationFrames[5...6])
        }
    }
    
    // ==== Functions to build enemy and player animations ====
    func buildPlayerAnimation() {
        //   ===  Frames for werewolf  ===
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
        
        //   ===  Frames for human tobias  ===
        //        Stand - 0,
        //        Walk1 - 1, Walk2 - 2, Walk3 - 3, Walk4 - 4
        //        Attack1 - 5, Attack2 - 6,
        //        Blockto - 7
        //        Damage1 - 8, Damage2 - 9
        //        Die1 - 10, Die2 - 11, Die3 - 12, Die4 - 13, Die5 - 14
        
        let tobiasAnimatedAtlas = SKTextureAtlas(named: "tobias")
        var animFramesT: [SKTexture] = []
        
        let numImagesT = tobiasAnimatedAtlas.textureNames.count
        for i in 1...numImagesT {
            let tobiasTextureName = "tobias\(i-1)"
            print(tobiasTextureName)
            animFramesT.append(tobiasAnimatedAtlas.textureNamed(tobiasTextureName))
            print(animFramesT)
        }
        tobiasAnimationFrames = animFramesT
    }
}
