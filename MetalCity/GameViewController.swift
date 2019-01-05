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

import Menu
import SnapKit

public struct DarkMenuTheme: MenuTheme {
    
    public let font = UIFont.systemFont(ofSize: 16, weight: .medium)
    public let textColor = UIColor(red: 13/255.0, green: 51/255.0, blue: 48/255.0, alpha: 1.0)
    public let brightTintColor = UIColor.white
    public let darkTintColor = UIColor.black
    public let highlightedTextColor = UIColor.white
    public let highlightedBackgroundColor = UIColor(red: 55/255.0, green: 188/255.0, blue: 174/255.0, alpha: 1.0)
    public let backgroundTint = UIColor(red: 25/255.0, green: 149/255.0, blue: 125/255.0, alpha: 0.11)
    public let gestureBarTint = UIColor(red: 13/255.0, green: 51/255.0, blue: 48/255.0, alpha: 0.17)
    public let blurEffect = UIBlurEffect(style: .light)
    public let shadowColor = UIColor(red: 13/255.0, green: 15/255.0, blue: 12/255.0, alpha: 1.0)
    public let shadowOpacity: Float = 1.0
    public let shadowRadius: CGFloat = 7.0
    public let separatorColor = UIColor(white: 0, alpha: 0.1)
    
    public init() {}
}


// Our iOS specific view controller
class GameViewController: UIViewController {

#if !targetEnvironment(simulator)
    var mtkView: MTKView!
    var device: MTLDevice!
#endif
    var renderer: Renderer!


    var menu : MenuView!
    var menuHidden : Bool = true
    var menuExpanded : Bool = false
    var menuRightConstraint: Constraint? = nil

    override var prefersHomeIndicatorAutoHidden: Bool { return true }

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isIdleTimerDisabled = true
        self.view.isMultipleTouchEnabled = true

        setupMenu()
        
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
        self.view.addGestureRecognizer(gr)
#endif

        let tapGr = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapGr.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGr)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }


    var prevPoint = CGPoint()
    var nrTouches = 0


    @objc func tap(_ gr: UITapGestureRecognizer) {
        menuHidden.toggle()
        
        
        if self.menuHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                UIView.animate(withDuration: 0.15) {
                    self.menuRightConstraint?.update(inset:-120)
                    self.view.layoutIfNeeded()
                }
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: {
                self.menuRightConstraint?.update(inset: 30)
                self.view.layoutIfNeeded()
            }, completion: { (complete) in
                UIView.animate(withDuration: 0.15) {
                    self.menuRightConstraint?.update(inset: 10)
                    self.view.layoutIfNeeded()
                }
            })
        }
    }
    
#if !targetEnvironment(simulator)
    @objc func pan(_ gr: UIPanGestureRecognizer) {
        let p = gr.location(in: self.view)
        switch gr.state {
        case .began:
            prevPoint = p
            nrTouches = gr.numberOfTouches
        case .changed:
            if gr.numberOfTouches != nrTouches {
                prevPoint = p
                nrTouches = gr.numberOfTouches
            }
            let dx = Float(p.x - prevPoint.x)
            let dy = Float(p.y - prevPoint.y)
            if nrTouches == 1 {
                if p.x < 100 {
                    rotateViewUpAndDown(dy:dy)
                } else if p.x > self.view.bounds.width - 100 {
                    raiseCamera(dy:dy)
                } else {
                    rotateView(dx:dx)
                }

            } else if nrTouches == 2 {
                rotateView(dx:dx)
                moveCamera(dy:dy)
            } else if nrTouches == 3 {
                raiseCamera(dy:dy)
                strafeCamera(dx:dx)
            }
            prevPoint = p
        default:
            break
        }
    }

    func rotateView(dx: Float) {
        renderer.camera.rotateViewRound(x: 0, y: dx * 0.01, z: 0)
    }

    func rotateViewUpAndDown(dy: Float) {
        let deltaY = -dy * 0.01
        var v = renderer.camera.lookAt
        v.y += deltaY * 30
        renderer.camera.lookAt = v
    }

    func moveCamera(dy: Float) {
        renderer.camera.moveCamera(speed: -dy * 0.01)
    }

    func raiseCamera(dy: Float) {
        renderer.camera.raiseCamera(amount: dy*0.1)
    }

    func strafeCamera(dx: Float) {
        renderer.camera.strafeCamera(speed: -dx * 0.005)
    }
#endif
}


// MARK: Menu
extension GameViewController {
    func setupMenu() {
        
        menu = MenuView(title: "Menu", theme: DarkMenuTheme()) { () -> [MenuItem] in
            return [
                ShortcutMenuItem(name: "Toggle autocam", shortcut: (.command, "Z"), action: {
                    [unowned self] in
                    
                    self.renderer.toggleAutocam()
                }),
                
                ShortcutMenuItem(name: "Next autocam mode", shortcut: ([.command, .shift], "Z"), action: {
                    [weak self] in

                    self?.renderer.changeAutocamMode()
                }),
                
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Rebuild city", shortcut: ([.command, .alternate], "I"), action: {
                    [weak self] in

                    self?.renderer.rebuildCity()
                }),
                ShortcutMenuItem(name: "Regenerate textures", shortcut: ([.command, .alternate], "L"), action: {
                    [weak self] in

                    self?.renderer.regenerateTextures()
                }),
                
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                ]
        }
        
        view.addSubview(menu)
        
        menu.tintColor = .black
        menu.contentAlignment = .left
        
        menu.snp.makeConstraints {
            make in
            
            self.menuRightConstraint = make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).inset(-200).constraint
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(30)

            //Menus don't have an intrinsic height
            make.height.equalTo(40)
        }
    }
    
}
