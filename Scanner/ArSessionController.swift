//
//  ArSessionController.swift
//  3dscanner
//
//  Created by tingyi on 2021/2/2.
//

import UIKit
import ARKit
import RealityKit

class ArSessionController: NSObject, ARSessionDelegate {

    var startTag: Bool = false
    var time0  = 0.0
    var time1  = 0.0
    let timeInterval = 0.5
    var frameIndex = 0
    // Arview and frameprocessor
    var frameProcessor: FrameProcessor = FrameProcessor()
    var objMeshProcessor: ObjMeshProcess = ObjMeshProcess()
    var arView: ARView?
    let configuration = ARWorldTrackingConfiguration()
    var dictName = ""
    let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
    // MARK: initialize arview
    func initialize(_ view: ARView) {
        arView = view
        if arView != nil {
            arView!.session.delegate = self

            //setupCoachingOverlay()
            arView!.environment.sceneUnderstanding.options = []

            // Turn on occlusion from the scene reconstruction's mesh.
//            arView!.environment.sceneUnderstanding.options.insert(.occlusion)

            // Turn on physics for the scene reconstruction's mesh.
//            arView!.environment.sceneUnderstanding.options.insert(.physics)

            // Display a debug visualization of the mesh.
            arView!.debugOptions.insert(.showSceneUnderstanding)

            
            //arView!.debugOptions.insert(.showAnchorGeometry)
            // For performance, disable render options that are not required for this app.
            arView!.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]

            // Manually configure what kind of AR session to run
            arView!.automaticallyConfigureSession = false
            
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.sceneReconstruction = .mesh
            configuration.environmentTexturing = .manual

            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyyMMddhhmmss"
            dictName = dateFormat.string(from: Date())

        }
    }

    // MARK: start scan real world
    func start() {
        if arView != nil {
            print(configuration.planeDetection)
            arView!.session.run(configuration)
        }

    }

    // MARK: stop scan
    func stop() {
        if arView != nil {
            arView!.session.pause()
            
            // remove redundant image
            deleteRedundant()
            objMeshProcessor.saveOBJ( arView!, dictName )
            arView!.debugOptions.remove(.showSceneUnderstanding)
            
            startTag = false
            
            let tex = texrecon(dictName);
               tex?.process();
        }
        
    }
    // pause
    func pause() {
        if arView != nil {
            arView!.session.pause() }
    }
    // go on
    func proceed() {
        if arView != nil {
            arView!.session.run(configuration)}
    }
    
    
    // delete redundant
    
    func deleteRedundant(){
        let imagePath = self.frameProcessor.imagePath.path
        let jsonPath = self.frameProcessor.jsonPath.path
        
        
        do {
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: imagePath) && fileManager.fileExists(atPath: jsonPath) {
                print("no redundant data ")
            }
            
            else if fileManager.fileExists(atPath: imagePath) && !fileManager.fileExists(atPath: jsonPath) {
                try! fileManager.removeItem(atPath: imagePath)
                
                print("removed redundant image")
            } else {
                print("delet file error")
            }
            
        }
        
        
        


        
    }
    
    
    
    
    func session(_ session: ARSession,
                 didUpdate frame: ARFrame) {

        //print("================  debug info ==============")

        if self.startTag == false {
            time0 = Double(frame.timestamp)
            startTag = true
        }
        let time1 = Double(frame.timestamp)
        let localDictName = dictName
        if time1 - time0 > timeInterval {
            // later will use other func to replace
            time0 = time1
            dispatchQueue.async() {
                self.frameProcessor.processFrame(frame, localDictName)

            }
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if !anchors.isEmpty{
            anchors.forEach { (anchor) in
                guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//                print("""
//                           Removing Plane Anchor = \(planeAnchor.classForCoder)
//                    """)
                session.remove(anchor: planeAnchor)
            }
        }
    }
    
    func dirname() -> String{
        return dictName;
    }
}
