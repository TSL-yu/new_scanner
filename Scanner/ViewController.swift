    /*
    See LICENSE folder for this sample’s licensing information.

    Abstract:
    Main view controller for the AR experience.
    */

    import UIKit
    import Metal
    import MetalKit
    import ARKit

    final class ViewController: UIViewController, ARSessionDelegate {
        
        
        
        @IBOutlet var mTKView: MTKView!
        
        private var sessionStarted: Bool = false
        private let isUIEnabled = true
        private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
        private let rgbRadiusSlider = UISlider()

        private let session = ARSession()
        private var renderer: Renderer!

        private var folderUrl : URL? = nil
        
        

        @IBAction func cameraClicked(_ sender: UIButton) {
             if sessionStarted {
                
                
                
                // save file path
                
                // url for file folder
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "yyyyMMddhhmmss"
                let dictname = dateFormat.string(from: Date())
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

                let folderUrl = documentsPath.appendingPathComponent("\(dictname)")
                do { try  FileManager.default.createDirectory(
                    at: folderUrl,
                    withIntermediateDirectories: true,
                    attributes: nil
                ) } catch { print(" create folder error") }
                
                self.folderUrl = folderUrl

                self.renderer.savePointsToFile(folderUrl: folderUrl)

        
                performSegue(withIdentifier: "showscene", sender: self)
                
            } else {
                sessionStarted = true
                guard let device = MTLCreateSystemDefaultDevice() else {
                    print("Metal is not supported on this device")
                    return
                }

                session.delegate = self

                // Set the view to use the default device
                mTKView.device = device

                mTKView.backgroundColor = UIColor.clear
                // we need this to enable depth test
                mTKView.depthStencilPixelFormat = .depth32Float
                mTKView.contentScaleFactor = 1
                mTKView.delegate = self

                // Configure the renderer to draw to the view
                renderer = Renderer(session: session, metalDevice: device, renderDestination: mTKView)
                renderer.drawRectResized(size: view.bounds.size)

                // Confidence control
                confidenceControl.backgroundColor = .white
                confidenceControl.selectedSegmentIndex = renderer.confidenceThreshold
                confidenceControl.addTarget(self, action: #selector(viewValueChanged), for: .valueChanged)

                // RGB Radius control
                rgbRadiusSlider.minimumValue = 0
                rgbRadiusSlider.maximumValue = 1.5
                rgbRadiusSlider.isContinuous = true
                rgbRadiusSlider.value = renderer.rgbRadius
                rgbRadiusSlider.addTarget(self, action: #selector(viewValueChanged), for: .valueChanged)

            }
        }
        
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            

//
//            let stackView = UIStackView(arrangedSubviews: [confidenceControl, rgbRadiusSlider])
//            stackView.isHidden = !isUIEnabled
//            stackView.translatesAutoresizingMaskIntoConstraints = false
//            stackView.axis = .vertical
//            stackView.spacing = 20
//            view.addSubview(stackView)
//            NSLayoutConstraint.activate([
//                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
//            ])

//            // Setup a save button
//            let button = UIButton(type: .system, primaryAction: UIAction(title: "Save", handler: { (action) in
//                self.renderer.savePointsToFile()
//            }))
//            button.translatesAutoresizingMaskIntoConstraints = false
//            self.view.addSubview(button)
//            NSLayoutConstraint.activate([
//                button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
//                button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
//            ])
            
}

        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if ( segue.identifier == "showscene" ) {
                let vc = segue.destination as! ScenViewController
                vc.filePath = self.renderer.filePath
                vc.folderUrl = self.folderUrl
            }
        }
        
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            // Create a world-tracking configuration, and
            // enable the scene depth frame-semantic.
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = .sceneDepth

            // Run the view's session
            session.run(configuration)

            // The screen shouldn't dim during AR experiences.
            UIApplication.shared.isIdleTimerDisabled = true
        }

        @objc
        private func viewValueChanged(view: UIView) {
            switch view {

            case confidenceControl:
                renderer.confidenceThreshold = confidenceControl.selectedSegmentIndex

            case rgbRadiusSlider:
                renderer.rgbRadius = rgbRadiusSlider.value

            default:
                break
            }
        }

        // Auto-hide the home indicator to maximize immersion in AR experiences.
        override var prefersHomeIndicatorAutoHidden: Bool {
            return true
        }

        // Hide the status bar to maximize immersion in AR experiences.
        override var prefersStatusBarHidden: Bool {
            return true
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            // Present an error message to the user.
            guard error is ARError else { return }
            let errorWithInfo = error as NSError
            let messages = [
                errorWithInfo.localizedDescription,
                errorWithInfo.localizedFailureReason,
                errorWithInfo.localizedRecoverySuggestion
            ]
            let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
            DispatchQueue.main.async {
                // Present an alert informing about the error that has occurred.
                let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
                let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                    alertController.dismiss(animated: true, completion: nil)
                    if let configuration = self.session.configuration {
                        self.session.run(configuration, options: .resetSceneReconstruction)
                    }
                }
                alertController.addAction(restartAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    
    
    

    // MARK: - MTKViewDelegate

    extension ViewController: MTKViewDelegate {
        // Called whenever view changes orientation or layout is changed
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer.drawRectResized(size: size)
        }

        // Called whenever the view needs to render
        func draw(in view: MTKView) {
            renderer.draw()
        }
    }
//
    // MARK: - RenderDestinationProvider

    protocol RenderDestinationProvider {
        var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
        var currentDrawable: CAMetalDrawable? { get }
        var colorPixelFormat: MTLPixelFormat { get set }
        var depthStencilPixelFormat: MTLPixelFormat { get set }
        var sampleCount: Int { get set }
    }

    extension MTKView: RenderDestinationProvider {

    }

    
