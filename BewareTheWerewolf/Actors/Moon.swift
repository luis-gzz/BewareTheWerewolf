//
//  Moon.swift
//  BewareTheWerewolf
//
//  Created by Luis Gonzalez on 8/25/18.
//  Copyright © 2018 Luis Gonzalez. All rights reserved.
//
import SpriteKit
import GameplayKit


class Moon {
    var sprite = SKSpriteNode();   // this property holds our actual SKSpriteNode
    
    var isWere = true
    var stage = 1;
    var isFull = false
    var fastnest = -20.0
    var startX = CGFloat(0.0)
    var moonFrames: [SKTexture] = []
    var moonSkullCount = 0
    
    init(x: CGFloat, y: CGFloat) {
        // SKSpriteNode
        //Set up the player
        buildMoonFrames()
        sprite = SKSpriteNode(texture: moonFrames[stage])
        sprite.texture?.filteringMode = SKTextureFilteringMode.nearest
        if (y > 480.0) {
            sprite.position = CGPoint(x: 2 * x + sprite.size.width - 100, y: y - 65)
        } else {
            sprite.position = CGPoint(x: 2 * x + sprite.size.width - 100, y: y - 55)
        }
        sprite.zPosition = -1.0
        startX = 2 * x + sprite.size.width;
        
        sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 28.0, height: 28.0))
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.velocity = CGVector(dx: fastnest, dy: 0.0)
        
    }
    
    func cycle(player: Player) {
        sprite.physicsBody?.velocity = CGVector(dx: fastnest, dy: 0.0)
        
        if (sprite.position.x < -sprite.size.width / 2) {
            stage = stage + 1;
            stage = stage == 1 || stage == 7 ? stage + 1 : stage
            if (stage == 6) {
                stage = 0
            }
            sprite.texture = moonFrames[stage];
            sprite.position.x = startX
            
            if (stage == 5){
                fastnest = -5.0
                isFull = true
                player.switchMode()
            } else if (stage ==  0) {
                fastnest = -20.0
                isFull = false
                if (player.isWere) {
                    player.switchMode()
                }
            } else {
                fastnest = -20.0
                isFull = false
            }
        }
    }
   
    // ==== Functions to build enemy and player animations ====
    func buildMoonFrames() {
        //   ===  Frames for moon  ===
        //        0-7
        //        Full Moon - 4
        
        
        let moonTextureAtlas = SKTextureAtlas(named: "moon")
        var animFrames: [SKTexture] = []
        
        let numImages = moonTextureAtlas.textureNames.count
        for i in 1...numImages {
            let moonTextureName = "\(i)"
            animFrames.append(moonTextureAtlas.textureNamed(moonTextureName))
        }
        moonFrames = animFrames
    }
}
