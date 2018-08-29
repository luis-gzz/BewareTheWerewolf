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
    var fastnest = CGFloat(1.25)
    var startX = CGFloat(0.0)
    var moonFrames: [SKTexture] = []
    
    init(x: CGFloat, y: CGFloat) {
        // SKSpriteNode
        //Set up the player
        buildMoonFrames()
        sprite = SKSpriteNode(texture: moonFrames[stage])
        sprite.texture?.filteringMode = SKTextureFilteringMode.nearest
        if (y > 480.0) {
            sprite.position = CGPoint(x: 2 * x + sprite.size.width, y: y - 75)
        } else {
            sprite.position = CGPoint(x: 2 * x + sprite.size.width, y: y - 55)
        }
        startX = 2 * x + sprite.size.width;
        
        
    }
    
    func cycle(player: Player) {
        sprite.position.x = sprite.position.x - fastnest
        
        if (sprite.position.x < -sprite.size.width / 2) {
            stage = stage + 1;
            stage = stage == 1 || stage == 7 ? stage + 1 : stage
            if (stage == 8) {
                stage = 0
            }
            sprite.texture = moonFrames[stage];
            sprite.position.x = startX
            
            if (stage == 4){
                fastnest = CGFloat(0.25)
                isFull = true
                //player.switchMode()
            } else if (stage ==  5) {
                fastnest = CGFloat(1.5)
                isFull = false
               // player.switchMode()
            } else {
                fastnest = CGFloat(1.5)
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
