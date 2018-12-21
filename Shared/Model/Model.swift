//
//  Model.swift
//  MetalSample
//
//  Created by Andy Qua on 12/07/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Metal

class Model: NSObject {
    var renderPipelineState: MTLRenderPipelineState!

    let vertexDescriptor = MTLVertexDescriptor()
    var uniformsBuffer: MTLBuffer!
    
    var vertexBuffer : MTLBuffer!
    var indexBuffer : MTLBuffer!

    func createLibraryAndRenderPipeline( device : MTLDevice, vertexFunction : String, fragmentFunction : String ) -> MTLRenderPipelineState {

        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: vertexFunction)
        let fragmentFunction = library?.makeFunction(name: fragmentFunction)
        
        // step 1: set up the render pipeline state
        
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float4 // position
        var offset = MemoryLayout<vector_float4>.size
        vertexDescriptor.attributes[1].offset = offset
        vertexDescriptor.attributes[1].format = MTLVertexFormat.float4 // normal
        offset += MemoryLayout<vector_float4>.size
        vertexDescriptor.attributes[2].offset = offset
        vertexDescriptor.attributes[2].format = MTLVertexFormat.float4 // color
        offset += MemoryLayout<vector_float4>.size
        vertexDescriptor.attributes[3].offset = offset
        vertexDescriptor.attributes[3].format = MTLVertexFormat.float2 // texture
        offset += MemoryLayout<vector_float2>.size
        vertexDescriptor.layouts[0].stride = offset
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float;
    
        let renderbufferAttachment = renderPipelineDescriptor.colorAttachments[0]!
        renderbufferAttachment.pixelFormat = MTLPixelFormat.bgra8Unorm
        renderbufferAttachment.isBlendingEnabled = true
        renderbufferAttachment.rgbBlendOperation = MTLBlendOperation.add
        renderbufferAttachment.alphaBlendOperation = MTLBlendOperation.add
        renderbufferAttachment.sourceRGBBlendFactor = MTLBlendFactor.one
        renderbufferAttachment.sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        renderbufferAttachment.destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        renderbufferAttachment.destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        renderPipelineDescriptor.colorAttachments[0] = renderbufferAttachment

        var rps: MTLRenderPipelineState!
        do {
            rps = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }
        catch let error {
            fatalError("\(error)")
        }
        
        return rps
    }
    
    func draw( commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer ) {
    }
}
