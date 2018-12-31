//
//  Sky.swift
//  MetalCity
//
//  Created by Andy Qua on 20/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class Sky: Model {
    var device : MTLDevice

    var vertices = [Vertex]()
    var indices = [UInt16]()

    init(device: MTLDevice) {
        self.device = device

        let vertexShader : String = "indexedVertexShader"
        let fragmentShader : String = "indexedFragmentShader"

        super.init()

        self.renderPipelineState = createLibraryAndRenderPipeline(device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader)

        buildDome()
    }

    func buildDome() {
        let radius :Float = 800
        let dtheta : Float = 15
        let dphi : Float = 15

        var n = 0
        var vlist = [Vertex]()
        for phi in stride(from:0, to:90-dphi+1, by:dphi) {
            for theta in stride(from:0, to:360 - dtheta+1, by:dtheta) {
                var p = float4(0, 0, 0, 1)

                p.x = radius * sinf(phi*DEGREES_TO_RADIANS) * cosf(theta*DEGREES_TO_RADIANS)
                p.z = radius * sinf(phi*DEGREES_TO_RADIANS) * sinf(theta*DEGREES_TO_RADIANS)
                p.y = radius * cosf(phi*DEGREES_TO_RADIANS)

                var v = Vertex()
                v.position = p
                vlist.append(v)

                n += 1
                p.x = radius * sinf((phi+dphi)*DEGREES_TO_RADIANS) * cosf(theta*DEGREES_TO_RADIANS)
                p.z = radius * sinf((phi+dphi)*DEGREES_TO_RADIANS) * sinf(theta*DEGREES_TO_RADIANS)
                p.y = radius * cosf((phi+dphi)*DEGREES_TO_RADIANS)
                v = Vertex()
                v.position = p
                vlist.append(v)

                n += 1
                p.x = radius * sinf(DEGREES_TO_RADIANS*phi) * cosf(DEGREES_TO_RADIANS*(theta+dtheta))
                p.z = radius * sinf(DEGREES_TO_RADIANS*phi) * sinf(DEGREES_TO_RADIANS*(theta+dtheta))
                p.y = radius * cosf(DEGREES_TO_RADIANS*phi)
                v = Vertex()
                v.position = p
                vlist.append(v)

                n += 1
                if phi > -90 && phi < 90 {
                    p.x = radius * sinf((phi+dphi)*DEGREES_TO_RADIANS) * cosf(DEGREES_TO_RADIANS*(theta+dtheta))
                    p.z = radius * sinf((phi+dphi)*DEGREES_TO_RADIANS) * sinf(DEGREES_TO_RADIANS*(theta+dtheta))
                    p.y = radius * cosf((phi+dphi)*DEGREES_TO_RADIANS)
                    v = Vertex()
                    v.position = p
                    vlist.append(v)

                    n += 1
                }
            }
        }

        // Generate texture coords
        let hTile : Float = 1
        let vTile : Float = 1
        for i in 0 ..< vlist.count {
            var vx = vlist[i].position.x
            var vy = vlist[i].position.y
            var vz = vlist[i].position.z

            let mag = sqrtf((vx*vx)+(vy*vy)+(vz*vz))
            vx /= mag
            vy /= mag
            vz /= mag
            var t = float2()
            t.x = hTile * (atan2f(vx, vz)/(Float.pi*2)) + 0.5
            t.y = vTile * (asinf(vy) / Float.pi) + 0.5
            vlist[i].texCoords = t
        }

        // Correct texture
        for i in 0 ..< vlist.count-2 {
            var t1 = vlist[i].texCoords
            var t2 = vlist[i+1].texCoords
            var t3 = vlist[i+2].texCoords

            if t1.x - t2.x > 0.9 {
                t2.x += 1.0
            }
            if t2.x - t1.x > 0.9 {
                t1.x += 1.0
            }
            if t1.x - t3.x > 0.9 {
                t3.x += 1.0
            }
            if t3.x - t1.x > 0.9 {
                t1.x += 1.0
            }
            if t2.x - t3.x > 0.9 {
                t3.x += 1.0
            }
            if t3.x - t2.x > 0.9 {
                t2.x += 1.0
            }
            if t1.y - t2.y > 0.8 {
                t2.y += 1.0
            }
            if t2.y - t1.y > 0.8 {
                t1.y += 1.0
            }
            if t1.y - t3.y > 0.8 {
                t3.y += 1.0
            }
            if t3.y - t1.y > 0.8 {
                t1.y += 1.0
            }
            if t2.y - t3.y > 0.8 {
                t3.y += 1.0
            }
            if t3.y - t2.y > 0.8 {
                t2.y += 1.0
            }

            vlist[i].texCoords = t1
            vlist[i+1].texCoords = t2
            vlist[i+2].texCoords = t3
        }

        // Convert vertices into trianglestrip
        var i : UInt16 = 0
        for var v in vlist {
            v.position.x += Float(WORLD_SIZE/2)
            v.position.z += Float(WORLD_SIZE/2)
            v.color = float4(1,0,0,1)
            v.normal = float4(1,0,0,1)
            vertices.append(v)

            indices.append(i)
            i += 1
        }


    }

    func createBuffers() {
        guard vertices.count > 0 else { return }

        vertexBuffer = device.makeBuffer(bytes:vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices sky"

        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: MemoryLayout<UInt16>.stride * indices.count,
                                        options: [])
        indexBuffer.label = "indices sky"
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

    override func draw(commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer) {
        guard indices.count > 0 else { return }
        if vertexBuffer == nil {
            self.createBuffers()
        }

        commandEncoder.setRenderPipelineState(self.renderPipelineState)

        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)

        if let texture = TextureManager.instance.textures[.sky] {
            commandEncoder.setFragmentTexture(texture, index: 0)
        } else {
            print("ARRGH!")
        }

        commandEncoder.drawIndexedPrimitives(type: .triangleStrip,
                                             indexCount: indices.count,
                                             indexType: .uint16,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
    }


}
