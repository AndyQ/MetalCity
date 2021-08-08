//
//  Tower.swift
//  MetalCity
//
//  Created by Andy Qua on 22/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class Towers: Model {
    var device: MTLDevice
    var vertices = [Vertex]()

    init(device: MTLDevice) {
        self.device = device

        let vertexShader: String = "radioTowerVertexShader"
        let fragmentShader: String = "radioTowerFragmentShader"

        super.init()

        self.renderPipelineState = createLibraryAndRenderPipeline(device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader)
    }

    func createRadioTower(center:SIMD3<Float>, height:Float) {
        let color = SIMD4<Float>(0, 0, 0, 1)

        print("Adding tower")
//        var center = SIMD3<Float>(50, 65, 50.5)
        let offset = height / 15.0

        //Radio tower
        let v: [Vertex] = [
           Vertex(position: SIMD4<Float>(center.x, center.y + height, center.z, 1.0), normal: .normal, color: color, texCoords: SIMD2<Float>(0, 0)),
           Vertex(position: SIMD4<Float>(center.x - offset, center.y, center.z - offset, 1.0), normal: .normal, color: color, texCoords: SIMD2<Float>(1, 1)),
           Vertex(position: SIMD4<Float>(center.x + offset, center.y, center.z - offset, 1.0), normal: .normal, color: color, texCoords: SIMD2<Float>(0, 1)),
           Vertex(position: SIMD4<Float>(center.x + offset, center.y, center.z + offset, 1.0), normal: .normal, color: color, texCoords: SIMD2<Float>(1, 1)),
           Vertex(position: SIMD4<Float>(center.x - offset, center.y, center.z + offset, 1.0), normal: .normal, color: color, texCoords: SIMD2<Float>(0, 1)),
           Vertex(position: SIMD4<Float>(center.x - offset, center.y, center.z - offset, 1.0), normal: .normal, color: color, texCoords: SIMD2<Float>(1, 1))
        ]

        // Add triangles
        for i in 1 ..< 5 {
            vertices.append(v[0])
            vertices.append(v[i])
            vertices.append(v[i+1])
        }

        DecorationManager.instance.addLight(position: SIMD3<Float>(center.x, center.y + height + 1.0, center.z), color: SIMD4<Float>(255.0/255.0, 192.0/255.0, 160.0/255.0, 1.0), size: 2, blink: true)
    }

    func createBuffers() {
        guard vertices.count > 0 else { return }
        vertexBuffer = device.makeBuffer(bytes:vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices tower"
    }

    func update()
    {
    }

    func prepareToDraw() {
    }

    func finishDrawing() {
    }

    override func draw(commandEncoder: MTLRenderCommandEncoder, sharedUniformsBuffer: MTLBuffer) {
        if vertices.count == 0 {
            return
        }
        if vertexBuffer == nil {
            self.createBuffers()
        }

        commandEncoder.setRenderPipelineState(self.renderPipelineState)

        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)

        if let texture = TextureManager.instance.textures[.lattice] {
            commandEncoder.setFragmentTexture(texture, index: 0)
        } else {
            print("ARRRGH!")
        }

        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }


}
