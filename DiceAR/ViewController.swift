//
//  ViewController.swift
//  DiceAR
//
//  Created by Herman Kwan on 4/25/18.
//  Copyright © 2018 Herman Kwan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    // Object in sceneKit
    var trackerNode: SCNNode!
    var diceNode: SCNNode!
    
    // Position of where we put it. It's used in meters
    var trackingPosition = SCNVector3Make(0.0, 0.0, 0.0)
    
    // Track if it started
    var started = false
    
    // Track if surface is founded
    var foundSurface = false
    
    var resetIsTapped = false
    
    let scanningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        label.text = "Scanning please wait..."
        label.layer.cornerRadius = 15
        label.clipsToBounds = true
        label.font = UIFont.boldSystemFont(ofSize: 25)
        return label
    }()
    
    let resetButton: UIButton = {
        let resetButton = UIButton(type: .system)
        resetButton.backgroundColor = UIColor.white
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        resetButton.setTitleColor(UIColor.black, for: .normal)
        resetButton.layer.cornerRadius = 7
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.isHidden = true
        return resetButton
    }()
    
    func setupViews() {
        sceneView.addSubview(scanningLabel)
        scanningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scanningLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60).isActive = true
        scanningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        scanningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        sceneView.addSubview(resetButton)
        resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        resetButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if started {
            
            diceNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            
            // impulse false will be like a rocket, true will make it shoot up
            diceNode.physicsBody?.applyForce(SCNVector3Make(0.0, 3.0, 0.0), asImpulse: true)
            roll(dice: diceNode)
            
        } else {
            
            // removes the tracker off the parent
            trackerNode.removeFromParentNode()
            started = true
            
            // invisible floor pane to hold onto the dice
            let floorPlane = SCNPlane(width: 50.0, height: 50.0)
            floorPlane.firstMaterial?.diffuse.contents = UIColor.clear
            
            // node to contain the floor plane
            let floorNode = SCNNode(geometry: floorPlane)
            // Floor node set position to the tracking position
            floorNode.position = trackingPosition
            floorNode.eulerAngles.x = -.pi * 0.5
            sceneView.scene.rootNode.addChildNode(floorNode)
            
            // floor will be static
            floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            
            if resetIsTapped == true {
                sceneView.scene.rootNode.addChildNode(diceNode)
                diceNode.position = SCNVector3Make(trackingPosition.x, trackingPosition.y + 0.05, trackingPosition.z) 
                diceNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            }
            
            // creates the dice
            guard let dice = sceneView.scene.rootNode.childNode(withName: "dice", recursively: false) else { return }
            diceNode = dice
            // position of dice is a bit higher than the floor
            diceNode.position = SCNVector3Make(trackingPosition.x, trackingPosition.y + 0.05, trackingPosition.z)
            diceNode.isHidden = false
            
            scanningLabel.isHidden = true
            resetButton.isHidden = false
        }
    }
    
    // Everytime the screen updates, it'll run this
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !started else { return }
 
        /*
        Find a position. Specifify that it'll be in the center of the screen. Types is listed in priority
         
         existing Plane = current existing plane
         
         featurePoint = unique feature planes (ex. shirts)
         
         estimatedHorizontalPlane = the estimated plane
        */

        DispatchQueue.main.async {
            
            self.test()
        }
    }
    
    @objc func resetButtonTapped() {
        diceNode.removeFromParentNode()
        trackerNode.removeFromParentNode()
        foundSurface = false
        started = false
        test()
        sceneView.scene.rootNode.addChildNode(trackerNode)
        resetIsTapped = true
    }
    
    // MARK: Roll Dice
    func roll(dice:SCNNode){
        
        let randomX = Float(arc4random_uniform(2) + 1)
        let randomY = Float(arc4random_uniform(4)+1)
        let randomZ = Float(arc4random_uniform(3)+1)
        dice.runAction(SCNAction.moveBy(x: 0.0, y: 1.0, z: 0.0, duration: 1))
        
        //Run Animation
        dice.runAction(
            SCNAction.rotateBy(
                x: CGFloat(randomX * 3),
                y: CGFloat(randomY * 5),
                z: CGFloat(randomZ * 5),
                duration: 0.5)
        )
    }
    
    func test() {
        guard let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: [.existingPlane, .featurePoint, .estimatedHorizontalPlane]).first else { return }
        
        // node's space relative to its scene's space
        let trans = SCNMatrix4(hitTest.worldTransform)
        self.trackingPosition = SCNVector3Make(trans.m41, trans.m42, trans.m43)
        
        // create the tracker just once
        if !self.foundSurface {
            
            self.scanningLabel.text = "Please tap to select a spot"
            let trackerPlane = SCNPlane(width: 0.2, height: 0.2)
            trackerPlane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "tracker")
            trackerPlane.firstMaterial?.isDoubleSided = true
            
            self.trackerNode = SCNNode(geometry: trackerPlane)
            // make it face flat down. minus 90 degrees
            self.trackerNode.eulerAngles.x = -.pi * 0.5
            // allow it to be double sided
            self.sceneView.scene.rootNode.addChildNode(self.trackerNode)
            self.foundSurface = true
        }
        self.trackerNode.position = self.trackingPosition
    }
}




