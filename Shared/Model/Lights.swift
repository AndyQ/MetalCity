//
//  Light.swift
//  MetalCity
//
//  Created by Andy Qua on 22/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class Light {
    var blinkInterval: Int = 0
    var color: float4 = float4(1,0,0,1)
    var size: Float = 0
    var position: float3 = .zero
}

class Lights: Model {
    var device: MTLDevice
    var vertices = [Vertex]()
    var indices = [UInt16]()

    var lightAngles = [[float2]]()

    var lights = [Light]()

    init(device: MTLDevice) {
        self.device = device

        let vertexShader: String = "lightsVertexShader"
        let fragmentShader: String = "lightsFragmentShader"

        super.init()

        // Calc light angles
        lightAngles = Array(repeating: Array(repeating: float2(0,0), count: 360), count: 5)
        for s in 0 ..< 5 {
            for i in 0 ..< 360 {
                lightAngles[s][i].x = cosf(Float(i) * DEGREES_TO_RADIANS) * (Float(s) + 0.5)
                lightAngles[s][i].y = sinf(Float(i) * DEGREES_TO_RADIANS) * (Float(s) + 0.5)
            }
        }

        self.renderPipelineState = createLibraryAndRenderPipeline(device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader)
    }

    func createLight(position:float3, color:float4, size:Float, blink:Bool) {

        let pos = float4(position.x, position.y, position.z, 1.0)
        let l = Light()
        l.blinkInterval = blink ? 1000 + randomInt(500): 0
        l.size = size
        l.position = position
        l.color = color
        lights.append(l)

        let v: [Vertex] = [
            Vertex(position: pos, normal: .normal, color: .color, texCoords: float2(0, 0)),
            Vertex(position: pos, normal: .normal, color: .color, texCoords: float2(1, 0)),
            Vertex(position: pos, normal: .normal, color: .color, texCoords: float2(1, 1)),
            Vertex(position: pos, normal: .normal, color: .color, texCoords: float2(0, 1))
        ]

        let start = UInt16(vertices.count)
        indices.append(contentsOf: [ 0 + start, 1 + start, 2 + start, 0 + start, 2 + start, 3 + start ])
        vertices.append(contentsOf: v)
    }



    func createBuffers() {
        guard vertices.count > 0 else { return }

        vertexBuffer = device.makeBuffer(bytes:vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices lights"

        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: MemoryLayout<UInt16>.stride * indices.count,
                                        options: [])
        indexBuffer.label = "indices lights"
    }

    func update()
    {
        guard vertexBuffer != nil else { return }
        var pointer = vertexBuffer.contents().bindMemory(to: Vertex.self, capacity: vertices.count)
        for light in lights {
            // 4 vertices per car
            updateLight(light:light, vertexPtr:pointer)

            pointer = pointer.advanced(by: 4)
        }
    }

    func updateLight(light:Light, vertexPtr: UnsafeMutablePointer<Vertex>) {

//        if (!Visible(_cell_x, _cell_z)) {
//            return
//        }

        let camera = appState.cameraState.angle


/*
         let camera_position = appState.cameraState.position
        if fabsf(camera_position.x - position.x) > state.render.fog_distance {
            return
        }
        if fabsf(camera_position.z - position.z) > state.render.fog_distance {
            return
        }
*/
        let c: float4
        if light.blinkInterval != 0 && getTickCount() % UInt64(light.blinkInterval) > 300 {
            // Turn Off
            c = .zero
        } else {
            c = light.color
        }

        let angle = Int(clampAngle(camera.y))
        let offset = lightAngles[Int(light.size)][angle]
        let vertSize = light.size + 0.5
        let position = light.position

        var ptr = vertexPtr
        ptr.pointee.position = float4(position.x + offset.x, position.y - vertSize, position.z + offset.y, 1)
        ptr.pointee.color = c
        ptr = ptr.advanced(by: 1)
        ptr.pointee.position = float4(position.x + offset.x, position.y + vertSize, position.z + offset.y, 1)
        ptr.pointee.color = c
        ptr = ptr.advanced(by: 1)
        ptr.pointee.position = float4(position.x - offset.x, position.y + vertSize, position.z - offset.y, 1)
        ptr.pointee.color = c
        ptr = ptr.advanced(by: 1)
        ptr.pointee.position = float4(position.x - offset.x, position.y - vertSize, position.z - offset.y, 1)
        ptr.pointee.color = c
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

        if let texture = TextureManager.instance.textures[.light] {
            commandEncoder.setFragmentTexture(texture, index: 0)
        } else {
            print("ARRRGH!")
        }

        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint16,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
    }
}
