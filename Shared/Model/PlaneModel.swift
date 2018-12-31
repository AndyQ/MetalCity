//
//  PlaneModel.swift
//  MetalCity
//
//  Created by Andy Qua on 15/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//


import MetalKit

class PlaneModel : Model {
    var name : String = ""

    var bufferProvider : BufferProvider!

    var device : MTLDevice
    var texture : MTLTexture!

    init( device: MTLDevice, vertexShader : String = "indexedVertexShader", fragmentShader : String = "indexedFragmentShader" ) {
        self.device = device

        super.init()

        bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: MemoryLayout<PerInstanceUniforms>.size * (1))


        self.renderPipelineState = createLibraryAndRenderPipeline( device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader  )
        createAsset( device: device  )
    }

    func setTexture( image: Image ) {

        guard let data = image.pngData() else { return }
        let loader = MTKTextureLoader(device: device)
        do {
            texture = try loader.newTexture(data: data, options: nil)
        }
        catch let error {
            fatalError("\(error)")
        }
    }

    func createAsset( device : MTLDevice ) {
        //Front

        let x1 : Float = 0
        let x2 : Float = Float(WORLD_SIZE)
        let y1 : Float = -0.02
        let z1 : Float = 0
        let z2 : Float = Float(WORLD_SIZE)
        let normal = vector_float4(0.0, 1.0, 0.0, 1.0)
        let color = float4(1,1,1,1)

        let verticesArray: [Vertex] = [
            Vertex(position:vector_float4(x1, y1, z1, 1.0), normal: normal, color: color, texCoords:vector_float2(0.0, 0.0)),
            Vertex(position:vector_float4(x2, y1, z1, 1.0), normal: normal, color: color, texCoords:vector_float2(1.0, 0.0)),
            Vertex(position:vector_float4(x1, y1, z2, 1.0), normal: normal, color: color, texCoords:vector_float2(0.0, 1.0)),
            Vertex(position:vector_float4(x2, y1, z2, 1.0), normal: normal, color: color, texCoords:vector_float2(1.0, 1.0)),
        ]
        let indices : [UInt16] = [ 0, 1, 2, 3 ]

        vertexBuffer = device.makeBuffer(bytes:verticesArray, length: verticesArray.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices plane"

        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: MemoryLayout<UInt16>.stride * indices.count,
                                        options: [])
        indexBuffer.label = "indices plane"
    }

    func update(  )
    {
        self.uniformsBuffer = bufferProvider.nextBuffer()

        let translation = float4x4(translate: [0,0,0])

        // copy matrices into uniform buffers
        var uniform = PerInstanceUniforms()
        uniform.modelMatrix = translation// * scale;
        uniform.normalMatrix = uniform.modelMatrix.upper_left3x3()

        uniform.r = 1
        uniform.g = 1
        uniform.b = 1
        uniform.a = 1.0

        memcpy(self.uniformsBuffer.contents() + MemoryLayout<PerInstanceUniforms>.stride*0, &uniform, MemoryLayout<PerInstanceUniforms>.stride)
    }

    func prepareToDraw() {
        _ = bufferProvider.availableResourcesSemaphore.wait(timeout: .distantFuture)
    }

    func finishDrawing() {
        self.bufferProvider.availableResourcesSemaphore.signal()
    }

    override func draw( commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer ) {
        commandEncoder.setRenderPipelineState(self.renderPipelineState)

        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)

        commandEncoder.setFragmentTexture(texture, index: 0)

        commandEncoder.drawIndexedPrimitives(type: .triangleStrip,
                                             indexCount: 4,
                                             indexType: .uint16,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
    }

}
