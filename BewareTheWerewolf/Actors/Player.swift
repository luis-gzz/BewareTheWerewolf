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
    
    var isWere = false
    var shouldMove = true
    var shouldAttack = false
    var currentAction = "standing"
    var wolfAnimationFrames: [SKTexture] = []
    var tobiasAnimationFrames: [SKTexture] = []
    
    var stoppingPt: CGPoint = CGPoint(x:0, y:0)
    
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
        self.sprite.texture = self.tobiasAnimationFrames[0]
        self.sprite.texture?.filteringMode = SKTextureFilteringMode.nearest
        self.sprite.setScale(0.85)
        
        sprite.position = CGPoint(x: midX, y: midY)
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 23.0, height: 16.0))
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.isDynamic = true
    }
    
    func setStoppingPoint(angle: CGFloat) {
        if (isWere) {
            stoppingPt = CGPoint(x: 75 * cos(angle) + sprite.position.x, y: 75 * sin(angle) + sprite.position.y)
        } else {
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
