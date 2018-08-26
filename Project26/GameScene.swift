//
//  GameScene.swift
//  Project26
//
//  Created by Charles Martin Reed on 8/25/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import CoreMotion //handles all motion detection in iOS
import SpriteKit
import GameplayKit

/*NOTES ON BITMASKS:
 categoryBitMask: number property that defines the type of object this object considers for collisions. Category must be attached to object for collisions to take place or to send notifications of said collision.
 
 collisionBitMask: number property that defines what category of objects this node can collides with. By default, this is set to "everything".
 
 contactTestBitMask: number propety that defines the type of collisions we want to be notified about. Contact with no collision bit mask means you'll be notified when they overlap, but objects won't bounce off of one another. By default, this is set to send no notifications at all.
 */

//SpriteKit expects bitmasks to be described used a UInt32
//we're going to use enums and their raw values
enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //PROPERTIES:
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var isGameOver = false
    
    var lastTouchPosition: CGPoint? //we're using this to test in sim with touch
    var motionManager: CMMotionManager!
    
    override func didMove(to view: SKView) {
        //set the default physics
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        //start collecting motion events
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        //load a background - for some reason I had to specify jpg here... :/
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        //show our label
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        addChild(scoreLabel)
        
        //load our level and put our player in it
        loadLevel()
        createPlayer()
        
        
    }
    
    //MARK:- Touch support for testing in simulator
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //if there's a touch event, set the location to that touch location and then update lastTouchPosition
        if let touch = touches.first {
            let location = touch.location(in: self)
            lastTouchPosition = location
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //if there's a touch event, set the location to that touch location and then update lastTouchPosition
        if let touch = touches.first {
            let location = touch.location(in: self)
            lastTouchPosition = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    //MARK:- Checking whether we contacted, but didn't collide
    func didBegin(_ contact: SKPhysicsContact) {
        //we know which node is our player, so we also know what node ISN'T our player
        if contact.bodyA.node == player {
            playerCollided(with: contact.bodyB.node!)
        } else if contact.bodyB.node == player {
            playerCollided(with: contact.bodyA.node!)
        }
    }
    
    func playerCollided(with node: SKNode) {
        //when player hits vortex, they are penalized.
        if node.name == "vortex" {
            //stop the ball from being a dynamic physics body, so that it stops moving once sucked in. End the game.
            node.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            //move the ball over the vortex, to simulate being sucked in. Scale down at same time. When done, remove the ball from parent. Finally, create the player ball again and re-enable control.
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence) {
                [unowned self] in
                self.createPlayer()
                self.isGameOver = false
            }
        } else if node.name == "star" {
            //when player hits star, the star should be removed and the player should score a point.
            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
            //when player hits the finish flag, the next level should be loaded.
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        //#if-#else-#endif specifies conditional compilation block. No braces because everything until the #else or #endif will execute.
        //we're using special compiler instructions to determine whether we're using the sim or the real hardware
        
        #if targetEnvironment(simulator)
        //unwrap the optional position property, calculate difference between the current touch and the player position, change gravity of the physics world according
        if let currentTouch = lastTouchPosition {
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x, dy: diff.y)
        }
        #else
          //poll our motion manager for player location info
        if let accelerometerData = motionManager.accelerometerData {
            //pass acceleration.y to dx and acceleration.x to dy because this is a landscape game
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    
    //MARK:- Player init
    func createPlayer() {
        
        //load player sprite, give sprite circle physics, add it to the scene
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        
        //set the physics body's allowsRotation to false. Marble shouldn't rotate, for realism's sake.
        player.physicsBody?.allowsRotation = false
        
        //give the player linearDamping of 0.5 so that there's a decent amount of friction to its movement and the ball appears to slow down naturally
        player.physicsBody?.linearDamping = 0.5
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        
          //combine the star, vortex and finsh to get the player's contactTestBitMask, i.e, the collisions we want to be notified about
        player.physicsBody?.collisionBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        
        //the player instance SHOULD be able to be stopped by the wall
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
    //MARK:- Level init
    func loadLevel() {
          //Our method currently loads level file from disk and splits it up by line
        if let levelPath = Bundle.main.path(forResource: "level1", ofType: "txt") {
            if let levelString = try? String(contentsOfFile: levelPath) {
                //Each line beomces one row of level data, so the method will loop over each character in a row to see what letter it is
                let lines = levelString.components(separatedBy: "\n")
                
                //reading the lines in reversed because Y:0 is at the BOTTOM of the screen in SpriteKit, so we want to get what would actually be the last line in the txt file first.
                for (row, line) in lines.reversed().enumerated() {
                    for (column, letter) in line.enumerated() {
                        //game world is 64x64, find position by multiplying row/column by 64. Add 32 to x and y because SpriteKit calculates positions from the CENTER of objects
                        let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                        
                        //5 options: space means empty space, 'x' means wall, 'v' means deadly vortex, 's' means star, 'f' means finish
                        if letter == "x" {
                            //create our wall
                            let node = SKSpriteNode(imageNamed: "block")
                            node.position = position
                            
                            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                            node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                            node.physicsBody?.isDynamic = false
                            addChild(node)
                            
                        } else if letter == "v" {
                            //create our vortex
                            let node = SKSpriteNode(imageNamed: "vortex")
                            node.name = "vortex"
                            node.position = position
                            
                            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                            //notify us when the player and the vortex collide
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            addChild(node)
                            
                        } else if letter == "s" {
                            //create our star
                            let node = SKSpriteNode(imageNamed: "star")
                            node.name = "star"
                            node.position = position
                            
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                            //notify us when the player and the star collide
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            addChild(node)
                            
                        } else if letter == "f" {
                            //create our finish flag
                            let node = SKSpriteNode(imageNamed: "finish")
                            node.name = "finish"
                            node.position = position
                            
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            addChild(node)
                        }

                        }
                    }
                }
            }
        }
    
}
