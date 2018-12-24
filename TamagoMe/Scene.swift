//
//  Scene.swift
//  TamagoMe
//
//  Created by Tristrum Comet Tuttle on 12/7/18.
//  Copyright © 2018 Tristrum Comet Tuttle. All rights reserved.
//

import SpriteKit
import ARKit

class Scene: SKScene {

    
    
    override func didMove(to view: SKView) {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
    func createGhostAnchor(){
        guard let sceneView = self.view as? ARSKView else {
            return
        }
        
        // Define 360º in radians
        let _360degrees = 2.0 * Float.pi
        
        // Create a rotation matrix in the X-axis
        let rotateX = simd_float4x4(SCNMatrix4MakeRotation(_360degrees * randomFloat(min: 0.0, max: 1.0), 1, 0, 0))
        
        // Create a rotation matrix in the Y-axis
        let rotateY = simd_float4x4(SCNMatrix4MakeRotation(_360degrees * randomFloat(min: 0.0, max: 1.0), 0, 1, 0))
        
        // Combine both rotation matrices
        let rotation = simd_mul(rotateX, rotateY)
        
        // Create a translation matrix in the Z-axis with a value between 1 and 2 meters
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1 - randomFloat(min: 0.0, max: 1.0)
        
        // Combine the rotation and translation matrices
        let transform = simd_mul(rotation, translation)
        
        // Create an anchor
        let anchor = ARAnchor(transform: transform)
        
        // Add the anchor
        sceneView.session.add(anchor: anchor)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the first touch
        guard let touch = touches.first else {
            return
        }
        // Get the location in the AR scene
        let location = touch.location(in: self)
        
        // Get the nodes at that location
        let hit = nodes(at: location)
        
        // Get the first node (if any)
        if let node = hit.first {
            let up1 = SKAction.moveTo(y: node.position.y+20, duration: 0.1)
            let up2 = SKAction.moveTo(y: node.position.y+30, duration: 0.1)
            let up3 = SKAction.moveTo(y: node.position.y+35, duration: 0.1)
            let down3 = SKAction.moveTo(y: node.position.y+30, duration: 0.1)
            let down2 = SKAction.moveTo(y: node.position.y+20, duration: 0.1)
            let down1 = SKAction.moveTo(y: node.position.y, duration: 0.1)
            node.run(SKAction.sequence([up1, up2, up3, down3, down2, down1]))
        }
    }
    
}
