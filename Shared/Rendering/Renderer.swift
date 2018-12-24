//
//  Renderer.swift
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

// Our platform independent renderer class

import GameplayKit
import Metal
import MetalKit
import simd

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100

let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}



#if targetEnvironment(simulator)
class Renderer: NSObject {
}
#else
class Renderer: NSObject, MTKViewDelegate {
    
    // Metal stuff
    public let device: MTLDevice
    
    let metalLayer : CAMetalLayer
    
    var commandQueue: MTLCommandQueue!
    var dynamicUniformBuffer: MTLBuffer!
    var depthState: MTLDepthStencilState!
    var colorMap: MTLTexture!
    var depthTexture: MTLTexture!
    
    var drawableSize = CGSize()

    var projectionMatrix = float4x4()

    var sharedBufferProvider : BufferProvider!
    var sharedUniformBuffer : MTLBuffer!

    var frameDuration : Float = 1.0 / 60.0;
    
    var city : City
    var camera : Camera
    var autoCam : AutoCamera
    var fireworks :FireworkScene
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        self.metalLayer = metalKitView.layer as! CAMetalLayer
        self.metalLayer.pixelFormat = MTLPixelFormat.bgra8Unorm;
        //self.metalLayer.framebufferOnly = false // <-- THIS

        self.drawableSize = metalKitView.drawableSize
        
        TextureManager.instance.createTextures(device:device)
        DecorationManager.instance.setup(device:device)

        camera = Camera(pos: [0, 85, 0], lookAt: [10, 80, 10])
        autoCam = AutoCamera(camera: camera)
        autoCam.isEnabled = true
        autoCam.randomBehaviour = true
        city = City(device:device)
        fireworks = FireworkScene(device:device)
        
        super.init()

        buildDescriptors( metalKitView: metalKitView)
        
        buildSharedUniformBuffers()
    }
    
    
    func buildDescriptors( metalKitView: MTKView ) {
        guard let queue = self.device.makeCommandQueue() else { return }
        self.commandQueue = queue

        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.isDepthWriteEnabled = true
        depthDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!
    }
    
    
    func buildSharedUniformBuffers() {
        
        sharedBufferProvider = BufferProvider(device: device, inflightBuffersCount: 3, sizeOfUniformsBuffer: MemoryLayout<Uniforms>.size)
    }

    func createDepthTexture(  ) {
        let drawableSize = metalLayer.drawableSize
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        descriptor.usage = MTLTextureUsage.renderTarget
        descriptor.storageMode = .private

        self.depthTexture = self.device.makeTexture(descriptor: descriptor)
        self.depthTexture.label = "Depth Texture"
    }

    
    func updateSharedUniforms( )
    {
        let aspect = Float(metalLayer.drawableSize.width / metalLayer.drawableSize.height)
        let fov :Float = (aspect > 1) ? (Float.pi / 4) : (Float.pi / 3); //.pi_2/5

        projectionMatrix = float4x4(perspectiveWithAspect: aspect, fovy: fov, near: 0.1, far: 2000)
        
        autoCam.update()

        let modelViewMatrix = camera.look()
        let modelViewProjectionMatrix = projectionMatrix * modelViewMatrix

        var uniforms = Uniforms()
        uniforms.viewProjectionMatrix = modelViewProjectionMatrix

        self.sharedUniformBuffer = sharedBufferProvider.nextBuffer( )
        memcpy(self.sharedUniformBuffer.contents(), &uniforms, MemoryLayout<Uniforms>.size)
    }

    func updateUniforms( )
    {
        updateSharedUniforms( )
        city.update()
        fireworks.update()
    }
    
    func createRenderPassWithColorAttachmentTexture( texture : MTLTexture ) -> MTLRenderPassDescriptor {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = texture;
        renderPass.colorAttachments[0].loadAction = MTLLoadAction.clear;
        renderPass.colorAttachments[0].storeAction = MTLStoreAction.store;
        
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        
        renderPass.depthAttachment.texture = self.depthTexture;
        renderPass.depthAttachment.loadAction = MTLLoadAction.clear;
        renderPass.depthAttachment.storeAction = MTLStoreAction.store;
        renderPass.depthAttachment.clearDepth = 1.0;
        
        return renderPass;
    }

    
    
    func draw(in view: MTKView) {
        city.prepareToDraw()
        fireworks.prepareToDraw()
        
        updateUniforms()

        if self.depthTexture == nil || (self.depthTexture.width != Int(metalLayer.drawableSize.width) ||
            self.depthTexture.height != Int(metalLayer.drawableSize.height)) {

            createDepthTexture()
        }
        
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        commandBuffer.addCompletedHandler { [unowned self] (_) in
            self.fireworks.finishedDrawing()
            self.city.finishDrawing()

        }

        guard let drawable = metalLayer.nextDrawable() else { return }
        let renderPass = createRenderPassWithColorAttachmentTexture( texture: drawable.texture )

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        commandEncoder.setFrontFacing(MTLWinding.counterClockwise)
        
        commandEncoder.setCullMode(MTLCullMode.none)

        commandEncoder.setDepthStencilState(self.depthState)
        
        city.draw( commandEncoder: commandEncoder, sharedUniformsBuffer: self.sharedUniformBuffer )
        fireworks.draw( commandEncoder: commandEncoder, sharedUniformsBuffer: self.sharedUniformBuffer )
        
        commandEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
        //let aspect = Float(size.width) / Float(size.height)
        //projectionMatrix = matrix_perspective_projection(aspect: aspect, fovy: radians_from_degrees(65), near: 0.1, far: 100.0)
    }
}

extension Renderer {
    func rebuildCity() {
        DecorationManager.instance.reset()
        city = City(device:device)
    }
    
    func regenerateTextures() {
        TextureManager.instance.createTextures(device:device)
    }
    
    func toggleAutoCam() {
        autoCam.isEnabled = !autoCam.isEnabled
    }

    func changeAutocamMode() {
        self.autoCam.nextBehaviour( manuallyChanged: true )
    }
}
#endif
