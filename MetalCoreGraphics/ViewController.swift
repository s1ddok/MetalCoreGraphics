//
//  ViewController.swift
//  MetalCoreGraphics
//
//  Created by Andrey Volodin on 04/03/2019.
//  Copyright © 2019 Andrey Volodin. All rights reserved.
//

import UIKit
import Alloy

// Returns a size of the 'inSize' aligned to 'align' as long as align is a power of 2
func alignUp(size: Int, align: Int) -> Int {
    #if DEBUG
    precondition(((align-1) & align) == 0, "Align must be a power of two")
    #endif

    let alignmentMask = align - 1

    return (size + alignmentMask) & ~alignmentMask
}

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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


        let image = context!.makeImage()!

        let uiimage = UIImage(cgImage: image)

        self.imageView.image = uiimage

        let metalContext = MTLContext(device: Metal.device)
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

