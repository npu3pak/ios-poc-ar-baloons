//
//  ViewController.swift
//  Baloons
//
//  Created by Evgeniy Safronov on 26.03.2020.
//  Copyright © 2020 evsafronov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    private var baloonNodePrototype: SCNNode!
    private var hittedBaloonNodePrototype: SCNNode!
    private var rotationTimer: Timer?
    
    private var trackingStatus: String? {
        didSet {
            print(trackingStatus ?? "")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        loadScene()
        initCoachingOverlayView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        config.providesAudioData = false
        config.worldAlignment = .gravity
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic
        sceneView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rotationTimer?.invalidate()
        sceneView.session.pause()
    }
    
    func initCoachingOverlayView() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = self.sceneView.session
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .tracking
        coachingOverlay.delegate = self
        
        self.sceneView.addSubview(coachingOverlay)
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        coachingOverlay.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func loadScene() {
        let baloonScene = SCNScene(named: "Baloon.scnassets/Baloon.scn")!
        baloonNodePrototype = baloonScene.rootNode.childNode(withName: "Baloon", recursively: false)!
        hittedBaloonNodePrototype = baloonScene.rootNode.childNode(withName: "HittedBaloon", recursively: false)!
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        showBaloon()
    }
    
    private func showBaloon() {
        let baloonNode = self.baloonNodePrototype.clone()
        baloonNode.position = SCNVector3(0, -0.3, -2)
        sceneView.scene.rootNode.addChildNode(baloonNode)
        startRotation(node: baloonNode)
    }
    
    private func startRotation(node: SCNNode) {
        if let timer = rotationTimer, timer.isValid {
            timer.invalidate()
        }
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [unowned self] _ in
            self.rotate(node: node, around: SCNVector3(0, 0, 0), angle: 0.0025)
        }
    }
    
    @IBAction func onTapGestureDetected(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        let allResults = sceneView.hitTest(point, options: nil)
        guard let result = allResults.first(where: { $0.node.name == "Baloon"} ) else {
            return
        }
        let baloonNode = result.node
        
        baloonNode.removeFromParentNode()
        
        let hittedBaloonNode = hittedBaloonNodePrototype.clone()
        hittedBaloonNode.isHidden = false
        sceneView.scene.rootNode.addChildNode(hittedBaloonNode)
        hittedBaloonNode.position = baloonNode.position
        
        showBaloon()
    }

    // MARK: - Utility
    
    private func rotate(node: SCNNode, around center: SCNVector3, angle: Float) {
        let x0 = center.x
        let z0 = center.z
        let x = node.position.x
        let z = node.position.z
        let newX = x0 + (x - x0) * cos(angle) - (z - z0) * sin(angle)
        let newZ = z0 + (z - z0) * cos(angle) + (x - x0) * sin(angle)
        node.position = SCNVector3(newX, node.position.y, newZ)
    }
}

extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession,
                 didFailWithError error: Error) {
        trackingStatus = "AR Session Failure: \(error)"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        trackingStatus = "AR Session Was Interrupted!"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        trackingStatus = "AR Session Interruption Ended"
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            trackingStatus = "Tracking:  Not available!"
        case .normal:
            trackingStatus = "Tracking: Normal"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                trackingStatus = "Tracking: Limited due to excessive motion!"
            case .insufficientFeatures:
                trackingStatus = "Tracking: Limited due to insufficient features!"
            case .initializing:
                trackingStatus = "Tracking: Initializing..."
            case .relocalizing:
                trackingStatus = "Tracking: Relocalizing..."
            @unknown default:
                trackingStatus = "Tracking: Unknown..."
            }
        }
    }
}

extension ViewController : ARCoachingOverlayViewDelegate {
  
  func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
  }
  
  func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
  }
  
  func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
  }
}
