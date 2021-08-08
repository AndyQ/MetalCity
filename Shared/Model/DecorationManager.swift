//
//  DecorationManager.swift
//  MetalCity
//
//  Created by Andy Qua on 22/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class DecorationManager {
    static let instance = DecorationManager()

    var device: MTLDevice!
    var towers: Towers!
    var streetlights: Streetlights!
    var lights: Lights!

    private init() {

    }

    func reset() {
        setup(device:device)
    }

    func setup(device:MTLDevice) {
        self.device = device
        towers = Towers(device:device)
        streetlights = Streetlights(device:device)
        lights = Lights(device:device)
    }

    func addRadioTower(center:SIMD3<Float>, height:Float) {
        towers.createRadioTower(center: center, height: height)
    }

    func addStreetLightStrip(atX x:Float, z:Float, width:Float, depth:Float, height:Float, color:SIMD4<Float>) {
        streetlights.addLightStrip(atX: x, z: z, width: width, depth: depth, height: height, color: color)
    }

    func addLight(position:SIMD3<Float>, color:SIMD4<Float>, size:Float, blink:Bool) {
        lights.createLight(position:position, color:color, size:size, blink:blink)
    }


    func update() {
        lights.update()
    }

    func draw(commandEncoder: MTLRenderCommandEncoder, sharedUniformsBuffer: MTLBuffer) {
        towers.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)
        streetlights.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)
        lights.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)
    }

}
