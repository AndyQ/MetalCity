//
//  Decoration.swift
//  MetalCity
//
//  Created by Andy Qua on 17/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class Streetlights: Model {
    var type: Int = 0
    var textureType: TextureType = .light
    var gridX: Int = 0
    var gridY: Int = 0

    var bufferProvider: BufferProvider!
    var device: MTLDevice

    var vertices = [Vertex]()
    var indices = [UInt16]()
    init(device: MTLDevice) {
        self.device = device

        let vertexShader: String = "indexedVertexShader"
        let fragmentShader: String = "indexedFragmentShader"

        super.init()

        self.renderPipelineState = createLibraryAndRenderPipeline(device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader)

    }

    func addLightStrip(atX x:Float, z:Float, width:Float, depth:Float, height:Float, color:SIMD4<Float>) {
        gridX = WorldMap.worldToGrid(Int(x + (width / 2)))
        gridY = WorldMap.worldToGrid(Int(z + (depth / 2)))

        textureType = .light

        var s: Float = 0
        var t: Float = 0
        if width < depth {
            s = 1.0
            t = Float(Int(depth / width))
        }
        else
        {
            t = 1.0
            s = Float(Int(width / depth))
        }

        let newVertices: [Vertex] = [
            Vertex(position:SIMD4<Float>(x, height, z, 1.0), normal: .normal, color: .color, texCoords:SIMD2<Float>(0, 0)),
            Vertex(position:SIMD4<Float>(x, height, z + depth, 1.0), normal: .normal, color: .color, texCoords:SIMD2<Float>(0, t)),
            Vertex(position:SIMD4<Float>(x + width, height, z + depth, 1.0), normal: .normal, color: .color, texCoords:SIMD2<Float>(s, t)),
            Vertex(position:SIMD4<Float>(x + width, height, z, 1.0), normal: .normal, color: .color, texCoords:SIMD2<Float>(s, 0))
        ]

        let start = UInt16(vertices.count)
        indices.append(contentsOf: [ 0 + start, 1 + start, 2 + start, 0 + start, 2 + start, 3 + start ])
        vertices.append(contentsOf: newVertices)
    }

    func createBuffers() {
        guard vertices.count > 0 else { return }

        vertexBuffer = device.makeBuffer(bytes:vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices streetlights"

        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: MemoryLayout<UInt16>.stride * indices.count,
                                        options: [])
        indexBuffer.label = "indices streetlights"
    }

    func update()
    {

        let translation = float4x4(translate: [0,0,0])

        // copy matrices into uniform buffers
        var uniform = PerInstanceUniforms()
        uniform.modelMatrix = translation// * scale
        uniform.normalMatrix = uniform.modelMatrix.upper_left3x3()

        uniform.r = 1
        uniform.g = 1
        uniform.b = 1
        uniform.a = 1.0
    }

    func prepareToDraw() {
    }

    func finishDrawing() {
    }

    override func draw(commandEncoder: MTLRenderCommandEncoder, sharedUniformsBuffer: MTLBuffer) {
        guard indices.count > 0 else { return }
        if vertexBuffer == nil {
            self.createBuffers()
        }

        commandEncoder.setRenderPipelineState(self.renderPipelineState)

        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)

        if let texture = TextureManager.instance.textures[textureType] {
            commandEncoder.setFragmentTexture(texture, index: 0)
        } else {
            print("ARRGH!")
        }

        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint16,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
    }
}
