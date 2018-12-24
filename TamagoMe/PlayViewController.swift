//
//  PlayViewController.swift
//  TamagoMe
//
//  Created by Tristrum Comet Tuttle on 12/7/18.
//  Copyright © 2018 Tristrum Comet Tuttle. All rights reserved.
//

import UIKit
import ARKit

class PlayViewController: UIViewController, ARSKViewDelegate {

    @IBOutlet weak var arView: ARSKView!
    
    var level = 1

    var filePath = ""
    
    var notRotating = true
    
    var friend : SKNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        arView.delegate = self
        
        if (UserDefaults.standard.integer(forKey: "level") >= 0) {
            self.level = UserDefaults.standard.integer(forKey: "level")
        }
        
        // Show statistics such as fps and node count
        arView.showsFPS = true
        arView.showsNodeCount = true
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        filePath = documentsDirectory.appendingPathComponent("image.jpg").path
        //print(filePath)
        
        let scene = Scene(size: arView.bounds.size)
        scene.scaleMode = .resizeFill
        arView.presentScene(scene)
        scene.createGhostAnchor()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        arView.session.run(configuration)
    }
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        let node = SKSpriteNode(imageNamed: filePath)
        node.name = "friend"
        self.friend = node
        return node
    }
    
    @IBAction func rotateNode(_ sender: UIGestureRecognizer) {
        let check = Int.random(in: 1...10)
        if (check <= level) {
            if (self.notRotating) {
                self.notRotating = false
                let a = SKAction.rotate(byAngle: 2.5, duration: 0.1)
                let b = SKAction.rotate(byAngle: 5, duration: 0.1)
                let c = SKAction.rotate(byAngle: 7.5, duration: 0.1)
                let d = SKAction.rotate(byAngle: 10, duration: 0.1)
                let e = SKAction.rotate(byAngle: 12.5, duration: 0.1)
                let f = SKAction.rotate(byAngle: 15, duration: 0.1)
                let g = SKAction.rotate(byAngle: 17.5, duration: 0.1)
                let h = SKAction.rotate(byAngle: 20, duration: 0.1)
                let i = SKAction.rotate(byAngle: 22.5, duration: 0.1)
                let j = SKAction.rotate(byAngle: 25, duration: 0.1)
                let k = SKAction.rotate(byAngle: 27.5, duration: 0.1)
                let l = SKAction.rotate(byAngle: 30, duration: 0.1)
                let m = SKAction.rotate(byAngle: 32.5, duration: 0.1)
                let n = SKAction.rotate(byAngle: 35, duration: 0.1)
                self.friend?.run(SKAction.sequence([a, b, c, d, e, f, g, h, i, j, k, l, m, n])) {
                    self.notRotating = true
                }
            }
        }
    }
    
    @IBAction func pinchNode(_ sender: UIGestureRecognizer) {
        let check = Int.random(in: 1...10)
        if (check <= level) {
            let a = SKAction.fadeOut(withDuration: 0.5)
            let b = SKAction.fadeIn(withDuration: 0.5)
            self.friend?.run(SKAction.sequence([a, b]))
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
