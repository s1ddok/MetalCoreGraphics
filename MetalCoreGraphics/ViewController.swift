//
//  ViewController.swift
//  MetalCoreGraphics
//
//  Created by Andrey Volodin on 04/03/2019.
//  Copyright © 2019 Andrey Volodin. All rights reserved.
//

import UIKit
import Alloy

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let context = CGContext(data: nil,
                                width: 512,
                                height: 512,
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
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



    }


}

