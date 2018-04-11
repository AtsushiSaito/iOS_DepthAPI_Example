//
//  ViewController.swift
//  SwiftDepth
//
//  Created by AtsushiSaito on 2018/04/12.
//  Copyright © 2018年 AtsushiSaito. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var HomeLabel: UILabel!

    var DeviceInput: AVCaptureDeviceInput!
    var PhotoOutput: AVCapturePhotoOutput!
    var CaptureSession: AVCaptureSession!
    var Camera: AVCaptureDevice!
    var PreView: UIView!
    
    private var photoData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.HomeLabel = UILabel()
        self.HomeLabel.text = "iOS11 DepthAPI TestApp"
        self.HomeLabel.frame = CGRectMake(0, 30, self.view.bounds.width, 20)
        self.HomeLabel.textAlignment = .center
        self.view.addSubview(self.HomeLabel)
        
        self.PreView = UIView()
        self.PreView.frame = CGRectMake(0, 60, self.view.bounds.width, self.view.bounds.height - 60)
        
        self.InitCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func InitCamera(){
        self.CaptureSession = AVCaptureSession()
        self.Camera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .back)
        
        do {
            self.DeviceInput = try AVCaptureDeviceInput(device: self.Camera)
        } catch let error as NSError {
            print(error)
        }
        
        if (self.CaptureSession.canAddInput(self.DeviceInput)) {
            self.CaptureSession.addInput(DeviceInput)
        }
        
        let PreviewLayer = AVCaptureVideoPreviewLayer(session: self.CaptureSession)
        
        PreviewLayer.frame = PreView.frame
        PreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.layer.addSublayer(PreviewLayer)
        
        self.CaptureSession.startRunning()
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

}

