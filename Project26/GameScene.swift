//
//  GameScene.swift
//  Project26
//
//  Created by Charles Martin Reed on 8/25/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

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

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        //load a background - for some reason I had to specify jpg here... :/
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        //load our level
        loadLevel()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //do things
    }
    
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
