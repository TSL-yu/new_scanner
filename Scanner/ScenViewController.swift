//
//  ScenViewController.swift
//  Scanner
//
//  Created by 于亭义 on 2021/8/3.
//


import UIKit
import SceneKit

class ScenViewController: UIViewController{
    
    @IBOutlet weak var sceneView: SCNView!
    var filePath = String()
    var folderUrl : URL? = nil
    override func viewDidLoad() {
    
        
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true);
        // create a new scene
        let scene = SCNScene()

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.0
        cameraNode.camera?.zFar = 10.0
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0.3)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 3, z: 3)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // retrieve the node
        let pc = PointCloud()
        pc.readNode(path: filePath)
        
        let pcNode = pc.getNode()
        pcNode.position = SCNVector3(x: 0, y: -0.1, z: 0)

        scene.rootNode.addChildNode(pcNode)

        // animate the 3d object
        pcNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))


        print("pc node is ok?   ",pc)
        // set the scene to the view
        sceneView.scene = scene

        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = true

        // show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // configure the view
        sceneView.backgroundColor = UIColor.black
        
        
        
        
        // save scnview snapshot
        
        let screenshot = sceneView.snapshot().pngData()
        let filepath = self.folderUrl!.appendingPathComponent("scn.png")
      
        if screenshot != nil {   try? screenshot?.write(to: filepath) }
           
//        do {
//            // 7
//            try fileToWrite.write(to: fileUrl, atomically: true, encoding: String.Encoding.ascii)
//            self.filePath = fileUrl.absoluteString
//
//        }
//        catch {
//            print("Failed to write PLY file", error)
//        }

        
    }
    
    
    
    @IBAction func BackToRootView(_ sender: Any) {
        print("we are trying to pop +++++++++++")
        self.navigationController?.popToRootViewController(animated: true)
    }
    
//    @IBAction func toRoot(_ sender: Any) {
//
//
//        print("we are trying to pop +++++++++++")
//        self.navigationController?.popToRootViewController(animated: true)
//    }
    
    
    

    
}

