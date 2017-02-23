//
//  GameScene.swift
//  Ball Munch
/**
 * Copyright (c) 2017 Learned Geek LLC
 *
 */

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    struct ShapeStack {
        var shapes = [SKNode]()
        mutating func push(_ item: SKNode) {
            shapes.append(item)
        }
        mutating func pop() -> SKNode? {
            if shapes.count > 0 {
                return shapes.removeLast()
            }
            return nil
        }// http://stackoverflow.com/questions/24051633/how-to-remove-an-element-from-an-array-in-swift
        mutating func destroy(named value: String) -> Int? {
            if let index = (shapes.index{$0.name == value}) {
                print ("Removed shape: \(shapes[index].name)")
                shapes.remove(at: index)
                return index
            }
            return nil
        }
    }
    
    var contentCreated = false
    var timeOfLastMove: CFTimeInterval = 0.0
    var stackofShapes = ShapeStack()
    var ballNumber:UInt32 = 0
    var shapeNumber:UInt32 = 0
    
    // BitMasks
    let BulletCategory:UInt32 = 0x1 << 0
    let BallCategory:UInt32 = 0x1 << 1
    let ShapeCategory:UInt32 = 0x1 << 2
    let BorderCategory:UInt32 = 0x1 << 3
    
    // Accelerometer Data
    let motionManager = CMMotionManager()
    
    // Scene Setup and Content Creation
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
            
            let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
            borderBody.categoryBitMask = BorderCategory
            borderBody.friction = 0
            self.physicsBody = borderBody
            
            physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
            physicsWorld.contactDelegate = self
            
            motionManager.startAccelerometerUpdates()
            
        }
    }
    /*
     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
     if let touch = touches.first {
     let location = touch.location(in: self)
     addChild(createRandomShape(at: location))
     }
     } */
    func createRandomShape(at location: CGPoint) -> SKNode? {
        let random = getRandomNumber(min: 1, max: 2)
        var shape : SKNode
        
        // limit number of items on screen at any one time
        // uncomment to allow unlimited
        /*
         if stackofShapes.shapes.count > 50 {
         return nil
         }
         */
        if random == 1 {
            shape = createBox(at: location)
        } else {
            shape = createCircle(at: location)
        }
        stackofShapes.push(shape)
        print("# of Shapes: \(stackofShapes.shapes.count)")
        //dump(stackofShapes)
        
        return shape
    }
    func createBox(at location: CGPoint) -> SKSpriteNode {
        let size = getRandomNumber(min: 32, max: 64)
        let box = SKSpriteNode(color: getRandomColor(), size: CGSize(width: size, height: size))
        
        shapeNumber += 1
        
        box.name = "box " + String(shapeNumber)
        box.physicsBody = SKPhysicsBody(rectangleOf: box.frame.size)
        box.physicsBody!.categoryBitMask = ShapeCategory
        box.position = location
        
        let text = SKLabelNode(text: String(shapeNumber))
        text.fontSize = 50
        text.fontColor = SKColor.darkText
        box.addChild(text)
        
        return box
    }
    func createCircle(at location: CGPoint) -> SKShapeNode {
        let size = CGFloat(getRandomNumber(min: 16, max: 32))
        let circle = SKShapeNode(circleOfRadius: size)
        
        shapeNumber += 1
        
        circle.name = "circle " + String(shapeNumber)
        circle.fillColor = getRandomColor()
        circle.physicsBody = SKPhysicsBody(circleOfRadius: size)
        circle.physicsBody!.categoryBitMask = ShapeCategory
        circle.physicsBody!.restitution = 1
        circle.position = location
        
        let text = SKLabelNode(text: String(shapeNumber))
        text.fontSize = 50
        text.fontColor = SKColor.darkText
        circle.addChild(text)
        
        return circle
    }
    // Set is more or less the same as an Array, with the exception that this collection has no order.
    // Whilst iterating over an Array will always show the first item first, the order of a Set is unpredictable.
    // Fetching a Set is slightly faster than an Array.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //let touchCount = touches.count
        //let firstTouch = touches.first
        //let tapCount = touch!.tapCount
        
        for touch in touches {
            let location = touch.location(in: self)
            if let shape = createRandomShape(at: location) {
                addChild(shape)
            }
        }
    }
    
    // drand48()  returns a Double value whereas the UIColour init method expects the value to be in CGFloat
    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    func getRandomNumber(min start: UInt32, max end: UInt32) -> Int {
        // between 0 and n-1
        return Int(arc4random_uniform(end) + start)
    }
    
    func createContent() {
        //createShip()
    }
    func createShip() {
        let ship = SKSpriteNode(imageNamed: "cannon.png")
        ship.name = "cannon"
        ship.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        ship.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 256, height: 256))
        ship.physicsBody!.isDynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.02
        self.addChild(ship)
        
        self.backgroundColor = SKColor.white
    }
    func createBullet() -> SKNode {
        var bullet: SKNode
        
        bullet = SKSpriteNode(color: SKColor.green, size: CGSize(width: 24, height: 16))
        bullet.name = "bullet"
        
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
        bullet.physicsBody!.isDynamic = true
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = BulletCategory
        bullet.physicsBody!.contactTestBitMask = ShapeCategory
        
        return bullet
    }
    func createBall() -> SKNode {
        var ball: SKSpriteNode
        //var text: SKLabelNode
        
        // Is there a bug here?  When using SKTexture the shape will not rotate
        // Others seem to have the same problem.  See the second link below
        // https://developer.apple.com/reference/spritekit/skphysicsbody#//apple_ref/occ/clm/SKPhysicsBody/bodyWithTexture:size:
        // http://stackoverflow.com/questions/35820238/physics-body-as-an-sktexture-does-not-rotate
        let ballTexture = SKTexture(imageNamed: "pacman.png")
        ball = SKSpriteNode(texture: ballTexture)
        
        ballNumber += 1
        
        //ball = SKSpriteNode(color: SKColor.red, size: CGSize(width: 24, height: 24))
        //ball = SKSpriteNode(imageNamed: "pacman.png")
        ball.name = "ball" + String(ballNumber)
        ball.position = CGPoint(x: 100, y:700)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: max(ball.size.width/3, ball.size.height/3))
        ball.physicsBody!.isDynamic = true
        ball.physicsBody!.affectedByGravity = false
        ball.physicsBody!.categoryBitMask = BallCategory
        ball.physicsBody!.contactTestBitMask = ShapeCategory | BorderCategory
        ball.physicsBody!.restitution = 1.01
        ball.physicsBody!.allowsRotation = true
        ball.physicsBody!.friction = 0
        ball.physicsBody!.mass = 0.02
        
        //        text = SKLabelNode(text: String(ballNumber))
        //        text.fontColor = SKColor.black
        //        text.fontSize = 50
        //        ball.addChild(text)
        
        addChild(ball)
        return ball
    }
    func fireBullets(forUpdate currentTime: CFTimeInterval) {
        if (currentTime - timeOfLastMove < 10) {
            return
        }
        
        let bullet = createBullet()
        
        bullet.position = CGPoint(
            x: 200,
            y: 200
        )
        
        let bulletDestination = CGPoint(x: 800, y: 500)
        
        fireBullet(
            bullet: bullet,
            toDestination: bulletDestination,
            withDuration: 2.0,
            andSoundFileName: "cartoon-pop.wav"
        )
        
        self.timeOfLastMove = currentTime
    }
    func bounceBalls(forUpdate currentTime: CFTimeInterval) {
        
        if (currentTime - timeOfLastMove < 10) {
            return
        }
        
        let ball = createBall()
        let force = getRandomNumber(min: 5, max: 10)
        ball.physicsBody!.applyImpulse(CGVector(dx: force, dy: force))
        
        self.timeOfLastMove = currentTime
    }
    
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
            ])
        
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        bullet.run(SKAction.group([bulletAction, soundAction]))
        
        addChild(bullet)
    }
    
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
        
        let random = getRandomNumber(min: 1, max: 3)
        
        var soundName: String
        
        switch random {
        case 1:
            soundName = "pop4.wav"
        case 2:
            soundName = "cartoon-pop.wav"
        case 3:
            soundName = "pop6.wav"
        default:
            soundName = "cartoon-pop.wav"
        }
        
        //if firstBody.categoryBitMask == BulletCategory && secondBody.categoryBitMask == ShapeCategory {
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == ShapeCategory {
            secondBody.node?.run(SKAction.sequence([SKAction.playSoundFileNamed(soundName, waitForCompletion: true), SKAction.removeFromParent()]))
            let removedShapeIndex = stackofShapes.destroy(named: (secondBody.node?.name)!)
            //print ("Removed Shape Index: \(removedShapeIndex)")
            print("# of Shapes: \(stackofShapes.shapes.count)")
            
            if self.frame.contains(firstBody.node!.frame) == false &&
                firstBody.node?.frame.intersects(self.frame) == false {
                firstBody.node?.removeFromParent()
            }
        }
        // apply a small vector force in the opposite direction to avoid balls getting "stuck" against the wall due to rounding errors in the native physics engine
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BorderCategory {
            let strengthY = 1.0 * ((firstBody.node?.position.y)! < self.frame.height / 2 ? 1 : -1)
            let strengthX = 1.0 * ((firstBody.node?.position.x)! < self.frame.width / 2 ? 1 : -1)
            //            print("Ball: \(firstBody.node?.name)")
            //            print("Frame height: \(self.frame.height)")
            //            print("PositionX: \(firstBody.node?.position.x)")
            //            print("PositionY: \(firstBody.node?.position.y)")
            //            print("StrengthX: \(strengthX)")
            //            print("StrengthY: \(strengthY)")
            let body = firstBody.node?.physicsBody!
            body?.applyImpulse(CGVector(dx: strengthX, dy: strengthY))
        }
    }
    
    /*     // http://stackoverflow.com/questions/27671391/spritekit-physics-in-swift-ball-slides-against-wall-instead-of-reflecting/29433778#29433778
     func didBeginContact(contact: SKPhysicsContact) {
     
     let otherNode = contact.bodyA.node == ball.sprite ? contact.bodyB.node : contact.bodyA.node
     
     if let obstacle = otherNode as? Obstacle {
     ball.onCollision(obstacle)
     }
     else if let border = otherNode as? SKSpriteNode {
     
     assert(border.name == "border", "Bad assumption")
     
     let strength = 1.0 * (ball.sprite.position.x < frame.width / 2 ? 1 : -1)
     let body = ball.sprite.physicsBody!
     body.applyImpulse(CGVector(dx: strength, dy: 0))
     }
     }
     */
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        
        // Only if the loop value is of type SKShapeNode is it bound to the constant
        for case let shape as SKShapeNode in self.children {
            //        if let shape = childNode(withName: "cannon") as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                // probably reversed because of landscape mode
                if fabs(data.acceleration.x) > 0.2 || fabs(data.acceleration.y) > 0.2{
                    shape.physicsBody!.applyForce(CGVector(dx: -100*CGFloat(data.acceleration.y), dy: 100*CGFloat(data.acceleration.x)))
                    //                    print("Acceleration X: \(data.acceleration.x)")
                    //                    print("Acceleration Y: \(data.acceleration.y)")
                }
            }
        }
        
    }
    override func update(_ currentTime: TimeInterval) {
        //fireBullets(forUpdate: currentTime)
        bounceBalls(forUpdate: currentTime)
        processUserMotion(forUpdate: currentTime)
    }
}
