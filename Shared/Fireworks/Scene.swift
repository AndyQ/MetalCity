
import MetalKit

protocol Drawable {
    func draw(time: Int64,
              bv: inout BufferWrapper,
              bc: inout BufferWrapper)
}


let BUFFER_BYTE_LEN = 10 * 1000 * 1000

class FireworkScene {
    private var m_fireworks = [Drawable]()
    private var next_launch: Int64

    var vertexBuffer: MTLBuffer! = nil
    var vertexColorBuffer: MTLBuffer! = nil
    var pipelineState: MTLRenderPipelineState! = nil

    let inflightSemaphore = DispatchSemaphore(value: 1)

    init(device:MTLDevice) {
        // Launch the first firework immediately
        next_launch = get_current_timestamp()

        createLibraryAndRenderPipeline(device: device)
    }

    func createLibraryAndRenderPipeline(device: MTLDevice) {
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "passThroughFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "passThroughVertex")!

        let psd = MTLRenderPipelineDescriptor()
        psd.vertexFunction = vertexProgram
        psd.fragmentFunction = fragmentProgram
        psd.colorAttachments[0].pixelFormat = .bgra8Unorm //view.colorPixelFormat
        psd.depthAttachmentPixelFormat = .depth32Float

        // Enable blending
        psd.colorAttachments[0].isBlendingEnabled = true
        psd.colorAttachments[0].rgbBlendOperation = .add
        psd.colorAttachments[0].alphaBlendOperation = .add
        psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        psd.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        psd.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: psd)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }

        vertexBuffer = device.makeBuffer(length: BUFFER_BYTE_LEN, options: [])
        vertexBuffer.label = "vertices"

        vertexColorBuffer = device.makeBuffer(length: BUFFER_BYTE_LEN, options: [])
        vertexColorBuffer.label = "colors"
    }


    private func launch_firework(current_time: Int64) {
        let fw = Firework(time: current_time) //, aspect_x: x_aspect_ratio)
        m_fireworks.append(fw)
        while m_fireworks.count > 10 {
            m_fireworks.remove(at:0)
        }
    }

    func update() {
        var bv = BufferWrapper(vertexBuffer)
        var bc = BufferWrapper(vertexColorBuffer)

        let curtime = get_current_timestamp()

        if curtime > next_launch {
            launch_firework(current_time: curtime)
            next_launch = curtime + Int64(random_range(lower:100000, 700000))
        }

        for fw in m_fireworks {
            fw.draw(time: curtime, bv: &bv, bc: &bc)
        }

        vertexCount = bv.pos / 4
    }

    var vertexCount = 0

    func prepareToDraw() {
        _ = inflightSemaphore.wait(timeout: .distantFuture)
    }

    func finishedDrawing() {
        self.inflightSemaphore.signal()
    }
    func draw(commandEncoder renderEncoder: MTLRenderCommandEncoder, sharedUniformsBuffer: MTLBuffer) {
        renderEncoder.pushDebugGroup("draw morphing triangle")
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(vertexColorBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.popDebugGroup()

    }
}
