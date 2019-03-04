//
//  ViewController.swift
//  MetalCoreGraphics
//
//  Created by Andrey Volodin on 04/03/2019.
//  Copyright © 2019 Andrey Volodin. All rights reserved.
//

import UIKit
import Alloy
import MetalKit
import MetalPerformanceShaders

// Returns a size of the 'inSize' aligned to 'align' as long as align is a power of 2
func alignUp(size: Int, align: Int) -> Int {
    #if DEBUG
    precondition(((align-1) & align) == 0, "Align must be a power of two")
    #endif

    let alignmentMask = align - 1

    return (size + alignmentMask) & ~alignmentMask
}

class ViewController: UIViewController {
    
    @IBOutlet weak var metalView: MTKView!


    let metalContext = MTLContext(device: Metal.device)

    var originalTexture: MTLTexture?
    var blurredTexture: MTLTexture?
    var renderState: MTLRenderPipelineState?

    override func viewDidLoad() {
        super.viewDidLoad()

        let puppyImage = UIImage(named: "puppy")!

        self.originalTexture = try! self.metalContext.texture(from: puppyImage.cgImage!)
        self.blurredTexture = self.originalTexture?.matchingTexture(usage: [.shaderRead, .shaderWrite])

        let blurShader = MPSImageGaussianBlur(device: self.metalContext.device,
                                              sigma: 24.0)

        try! self.metalContext.scheduleAndWait { buffer in
            blurShader.encode(commandBuffer: buffer,
                              sourceTexture: self.originalTexture!,
                              destinationTexture: self.blurredTexture!)
        }

        let defaultLibrary = self.metalContext.standardLibrary!
        let fragment = defaultLibrary.makeFunction(name: "fragmentFunc")
        let vertex = defaultLibrary.makeFunction(name: "vertexFunc")

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment

        self.renderState = try! self.metalContext
                                    .device
                                    .makeRenderPipelineState(descriptor: descriptor)

        self.metalView.depthStencilPixelFormat = .invalid
        self.metalView.device = self.metalContext.device
        self.metalView.delegate = self

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let pagesize = Int(getpagesize())
        let width = 512
        let height = 512
        let bytesPerRow = width * 1
        var data: UnsafeMutableRawPointer? = nil
        let result = posix_memalign(&data, pagesize, alignUp(size: width * height * bytesPerRow, align: pagesize))

        let context = CGContext(data: data,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)

        context?.setLineWidth(10.0)
        context?.setStrokeColor(gray: 1.0, alpha: 1.0)
        context?.beginPath()
        context?.move(to: .zero)
        context?.addLine(to: CGPoint(x: 512, y: 512))
        context?.strokePath()

        let buffer = metalContext.device.makeBuffer(bytesNoCopy: context!.data!,
                                                    length: context!.bytesPerRow * context!.height,
                                                    options: .storageModeShared,
                                                    deallocator: nil)

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .r8Unorm
        textureDescriptor.width = context!.width
        textureDescriptor.height = context!.height
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = .shaderRead

        let texture = buffer!.makeTexture(descriptor: textureDescriptor,
                                          offset: 0,
                                          bytesPerRow: context!.bytesPerRow)
    }

}

extension ViewController: MTKViewDelegate {
    func draw(in view: MTKView) {
        try? self.metalContext.scheduleAndWait { buffer in
            buffer.render(descriptor: view.currentRenderPassDescriptor!) { encoder in
                encoder.setRenderPipelineState(self.renderState!)
                encoder.set(fragmentTextures: [self.originalTexture, self.blurredTexture, nil])
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }

            buffer.present(view.currentDrawable!)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
