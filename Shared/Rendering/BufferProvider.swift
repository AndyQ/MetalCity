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
    private(set) var availableResourcesSemaphore: DispatchSemaphore

    init(device:MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {

        availableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)

        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = (0..<inflightBuffersCount).map { _ in
            device.makeBuffer(length: sizeOfUniformsBuffer, options: [])!
        }
    }

    deinit{
        for _ in 0...self.inflightBuffersCount{
            self.availableResourcesSemaphore.signal()
        }
    }


    func nextBuffer() -> MTLBuffer {
        defer {
            availableBufferIndex = (availableBufferIndex + 1) % inflightBuffersCount
        }
        return uniformsBuffers[availableBufferIndex]
    }
}
