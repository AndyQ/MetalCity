//
//  GameViewController.swift
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import MetalKit
import CoreMotion
import UserNotifications


// Our iOS specific view controller
class GameViewController: UIViewController {
    
#if !targetEnvironment(simulator)
    var mtkView: MTKView!
    var device : MTLDevice!
#endif


    var renderer: Renderer!
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        self.view.isMultipleTouchEnabled = true
        

#if targetEnvironment(simulator)
        renderer = Renderer()
#else

        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        
        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        
        device = defaultDevice
        
        mtkView.device = device
        mtkView.backgroundColor = UIColor.black

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
#endif
        
        let gr = UIPanGestureRecognizer(target: self, action: #selector(GameViewController.pan(_:)))
        self.view.addGestureRecognizer(gr)

    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    var prevPoint = CGPoint()
    var nrTouches = 0

    @objc func pan( _ gr: UIPanGestureRecognizer ) {
        let p = gr.location(in: self.view)
        if gr.state == .began {
            prevPoint = p
            nrTouches = gr.numberOfTouches
        } else if gr.state == .changed {
            if gr.numberOfTouches != nrTouches {
                prevPoint = p
                nrTouches = gr.numberOfTouches
            }
            let dx = Float(p.x - prevPoint.x)
            let dy = Float(p.y - prevPoint.y)
            if nrTouches == 1 {

                renderer.camera.rotateViewRound(x: 0, y: dx / 100.0, z: 0)

                renderer.camera.moveCamera(speed: -dy * 0.05)
            } else if nrTouches == 2 {
                let deltaY = -dy / 100.0
                var v = renderer.camera.getView()
                v.y += deltaY * 30
                renderer.camera.setView(view:v)
                    
            } else if nrTouches == 3 {
                renderer.camera.raiseCamera(amount: dy*0.5)
                renderer.camera.strafeCamera(speed: -dx * 0.05)
            }
            prevPoint = p
        }
    }
    
/*
    var prevPoint = CGPoint()
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self.view)
        
        prevPoint = p
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self.view)
        
        let touchCount = event?.touches(for: self.view)?.count ?? 0
        print( "TouchCount - \(touchCount)" )
        
        renderer.camera.moveCameraByMouse(prevPoint: prevPoint, newPoint: p)
        prevPoint = p
    }
*/
}
