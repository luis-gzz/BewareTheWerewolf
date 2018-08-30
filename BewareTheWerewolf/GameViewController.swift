//
//  GameViewController.swift
//  BewareTheWerewolf
//
//  Created by Luis Gonzalez on 7/24/18.
//  Copyright © 2018 Luis Gonzalez. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        var sceneSize = CGSize(width: 270.0, height: 480.0)
        if (UIScreen.main.nativeBounds.height == 2436) {
            sceneSize = CGSize(width: 270.0, height: 585.0)
        }
        
        
        let skView = view as! SKView
            // Create the scene programmatically
            let scene = GameScene(size: sceneSize)
            
            scene.scaleMode = .aspectFill
            
            if (UIScreen.main.nativeBounds.height == 2436) {
                skView.preferredFramesPerSecond = 60
            }
            
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.presentScene(scene)
        
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if let skView = view as? SKView, let scene = skView.scene as? GameScene {
                scene.shake()
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
