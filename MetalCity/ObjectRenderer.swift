//
//  Layout.swift
//  MetalSample
//
//  Created by Andy Qua on 13/07/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Metal

class ObjectRenderer {
    var cubePipelineState: MTLRenderPipelineState!
    var cubeBufferProvider : BufferProvider!
    var cubeUniformBuffer : MTLBuffer!

    var cubes = [Cube]()
    var cubeMesh : CubeModel!
    var nrCubes : Int = 0
    var nrHiddenCubes : Int = 0

    init( device: MTLDevice ) {
        cubeMesh = CubeModel( device: device )
        self.nrCubes = 10
        
        setupBuffers(device: device, maxCubes: nrCubes)
        
        let position = vector_float4( 0, 3, -10, 1)
        let cube = Cube( position: position, color: vector_float4 ( 1, 1, 1, 1))

        self.cubes.append(cube)
    }
    
    deinit {
    }
    
    func setupBuffers( device: MTLDevice,  maxCubes: Int ) {
        cubeBufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: MemoryLayout<PerInstanceUniforms>.size * (maxCubes))
        
        print( "Allocated CubeBuffer with \(maxCubes)" )
    }

    func update(  )
    {
        
        self.cubeUniformBuffer = cubeBufferProvider.nextBuffer()
        
        var i = 0
        cubes.forEach {  cube in
                
            
//            let scaleVal : Float = i < 30 ? 0.2 : 0.5
//            let scale = matrix_scale(s: float3(scaleVal))
            let translation = float4x4(translate: cube.position.xyz)
            
            // copy matrices into uniform buffers
            var uniform = PerInstanceUniforms()
            uniform.modelMatrix = translation// * scale;
            uniform.normalMatrix = uniform.modelMatrix.upper_left3x3()
            
            uniform.r = cube.color[0];
            uniform.g = cube.color[1];
            uniform.b = cube.color[2];
            uniform.a = 1.0
            
            memcpy(self.cubeUniformBuffer.contents() + MemoryLayout<PerInstanceUniforms>.stride*i, &uniform, MemoryLayout<PerInstanceUniforms>.stride)
            
            i += 1
        }
    }
    func prepareToDraw() {
        _ = cubeBufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    func finishDrawing() {
        self.cubeBufferProvider.avaliableResourcesSemaphore.signal()
    }
    
    func draw( commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer ) {
        if nrCubes == 0 {
            return 
        }
        guard let uniformBuffer = self.cubeUniformBuffer else { return }
        
        let vertexCount = self.cubeMesh.nrVertices
        
        commandEncoder.setRenderPipelineState(self.cubeMesh.renderPipelineState)
        
        commandEncoder.setVertexBuffer(self.cubeMesh.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
        
        commandEncoder.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: nrCubes)
    }
}
