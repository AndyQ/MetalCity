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

    @IBOutlet weak var menuVCView: UIView!
#if !targetEnvironment(simulator)
    var mtkView: MTKView!
    var device : MTLDevice!
#endif
    var renderer: Renderer!


    weak var popUpView : UIView?

    override var prefersHomeIndicatorAutoHidden: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isIdleTimerDisabled = true
        self.view.isMultipleTouchEnabled = true

        menuVCView.isHidden = true

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

#if !targetEnvironment(simulator)
        let gr = UIPanGestureRecognizer(target: self, action: #selector(pan))
        gr.delegate = self
        self.view.addGestureRecognizer(gr)
#endif

        let tapGr = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapGr.delegate = self
        tapGr.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGr)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MenuViewController {
#if !targetEnvironment(simulator)
            vc.menuSelected = { [unowned self] (menuItem) in
                switch menuItem {
                case .toggleAutocam:
                    self.renderer.toggleAutoCam()
                case .nextAutocamMode:
                     self.renderer.changeAutocamMode()
                case .rebuildCity:
                    self.renderer.rebuildCity()
                case .regenerateTextures:
                    self.renderer.regenerateTextures()
                }
            }
#endif
        }
    }

    var prevPoint = CGPoint()
    var nrTouches = 0

    @objc func tap( _ gr: UITapGestureRecognizer ) {
        if !menuVCView.isHidden {
            let p = gr.location(in: self.view)
            if !menuVCView.frame.contains( p ) {
                menuVCView.isHidden = true
            }
        } else {
            menuVCView.isHidden = !menuVCView.isHidden

/*
            let v = MenuView(frame:CGRect(x:self.view.bounds.width-210, y:30, width:180, height:175 ))
            self.view.addSubview(v)
            self.popUpView = v
*/
        }
    }

#if !targetEnvironment(simulator)
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
                if p.x < 100 {
                    rotateViewUpAndDown( dy:dy)
                } else if p.x > self.view.bounds.width - 100 {
                    raiseCamera( dy:dy)
                } else {
                    rotateView( dx:dx )
                }

            } else if nrTouches == 2 {
                rotateView( dx:dx )
                moveCamera( dy:dy)
            } else if nrTouches == 3 {
                raiseCamera( dy:dy)
                strafeCamera( dx:dx)
            }
            prevPoint = p
        }
    }

    func rotateView( dx : Float ) {
        renderer.camera.rotateViewRound(x: 0, y: dx * 0.01, z: 0)
    }

    func rotateViewUpAndDown(dy : Float ) {
        let deltaY = -dy * 0.01
        var v = renderer.camera.getView()
        v.y += deltaY * 30
        renderer.camera.setView(view:v)
    }

    func moveCamera( dy : Float ) {
        renderer.camera.moveCamera(speed: -dy * 0.01)
    }

    func raiseCamera( dy : Float ) {
        renderer.camera.raiseCamera(amount: dy*0.1)
    }

    func strafeCamera( dx : Float ) {
        renderer.camera.strafeCamera(speed: -dx * 0.005)
    }
#endif
}

extension GameViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view!.isDescendant(of: menuVCView) {
            return false
        }
        return true
    }
}
