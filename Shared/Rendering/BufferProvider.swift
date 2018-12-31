//
//  BufferProvider.swift
//  MetalSample
//
//  Created by Andy Qua on 12/07/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class BufferProvider {
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var availableBufferIndex: Int = 0
    var avaliableResourcesSemaphore: DispatchSemaphore

    init(device:MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {

        avaliableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)

        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()
        
        for _ in 0..<inflightBuffersCount {
            let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])!
            uniformsBuffers.append(uniformsBuffer)
        }
    }
    
    deinit{
        for _ in 0...self.inflightBuffersCount{
            self.avaliableResourcesSemaphore.signal()
        }
    }


    func nextBuffer() -> MTLBuffer {
        
        let buffer = uniformsBuffers[availableBufferIndex]
                
        availableBufferIndex += 1
        if availableBufferIndex == inflightBuffersCount{
            availableBufferIndex = 0
        }
        
        return buffer
    }
}
