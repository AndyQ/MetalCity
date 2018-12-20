//
//  GameViewController.swift
//  MetalCity_Mac
//
//  Created by Andy Qua on 19/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
    }
    
    var prevPoint = CGPoint()
    var nrTouches = 0
    
    override func mouseDown(with event: NSEvent) {
        let p = event.locationInWindow
        prevPoint = p
    }

    override func mouseDragged(with event: NSEvent) {
        let p = event.locationInWindow
        
        let cmdPressed = event.modifierFlags.contains(.command)
        let optionPressed = event.modifierFlags.contains(.option)

        let dx = Float(p.x - prevPoint.x)
        let dy = Float(p.y - prevPoint.y)
        if !cmdPressed && !optionPressed {
            
            renderer.camera.rotateViewRound(x: 0, y: dx / 100.0, z: 0)
            
            renderer.camera.moveCamera(speed: -dy * 0.05)
        } else if cmdPressed {
            let deltaY = -dy / 100.0
            var v = renderer.camera.getView()
            v.y += deltaY * 30
            renderer.camera.setView(view:v)
            
        } else if optionPressed {
            renderer.camera.raiseCamera(amount: dy*0.5)
            renderer.camera.strafeCamera(speed: -dx * 0.05)
        }
        prevPoint = p
    }
    

/*
    @objc func pan( _ gr: NSPanGestureRecognizer ) {
        let p = gr.location(in: self.view)
        let buttonMask = gr.buttonMask
        
        print( "ButtonMask \(buttonMask)"   )
        if gr.state == .began {
            lastButtonMask = buttonMask
            prevPoint = p
        } else if gr.state == .changed {
            if buttonMask != lastButtonMask {
                prevPoint = p
                lastButtonMask = buttonMask
            }
            let dx = Float(p.x - prevPoint.x)
            let dy = Float(p.y - prevPoint.y)
            if buttonMask == 1 {
                
                renderer.camera.rotateViewRound(x: 0, y: dx / 100.0, z: 0)
                
                renderer.camera.moveCamera(speed: -dy * 0.05)
            } else if buttonMask == 2 {
                let deltaY = -dy / 100.0
                var v = renderer.camera.getView()
                v.y += deltaY * 30
                renderer.camera.setView(view:v)
                
            } else if buttonMask == 3 {
                renderer.camera.raiseCamera(amount: dy*0.5)
                renderer.camera.strafeCamera(speed: -dx * 0.05)
            }
            prevPoint = p
        }
    }
*/

}
