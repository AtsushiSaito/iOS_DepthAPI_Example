//
//  ViewController.swift
//  SwiftDepth
//
//  Created by AtsushiSaito on 2018/04/12.
//  Copyright © 2018年 AtsushiSaito. All rights reserved.
//

import UIKit
import AVFoundation

extension ViewController: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        let DepthSyncData = synchronizedDataCollection.synchronizedData(for: self.DepthOutput) as? AVCaptureSynchronizedDepthData
        let DepthData = DepthSyncData?.depthData
        
        if (DepthData != nil){
            let DepthImage = CIImage(cvPixelBuffer: (DepthData?.applyingExifOrientation(.right).depthDataMap)!)
            DispatchQueue.main.async {
                self.DepthImageView.image = UIImage(ciImage: DepthImage)
            }
        }
        
        let VideoSyncData = synchronizedDataCollection.synchronizedData(for: self.VideoOutput) as? AVCaptureSynchronizedSampleBufferData
        let SampleBuffer = VideoSyncData?.sampleBuffer
        if (VideoSyncData?.sampleBufferWasDropped == false) {
            DispatchQueue.main.async {
                let Image = self.UIImageFromCMSamleBuffer(buffer: SampleBuffer!)
                self.VideoImageView.image = Image
            }
        } else {
            print("true")
        }
    }
}

class ViewController: UIViewController {
    
    var HomeLabel: UILabel!

    var DeviceInput: AVCaptureDeviceInput!
    
    var PhotoOutput: AVCapturePhotoOutput!
    var DepthOutput: AVCaptureDepthDataOutput!
    var VideoOutput: AVCaptureVideoDataOutput!
    var SyncOutput: AVCaptureDataOutputSynchronizer!
    
    var CaptureSession: AVCaptureSession!
    var Camera: AVCaptureDevice!
    
    var DepthImageView: UIImageView!
    var VideoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.HomeLabel = UILabel()
        self.HomeLabel.text = "iOS11 DepthAPI TestApp"
        self.HomeLabel.frame = CGRectMake(0, 30, self.view.bounds.width, 20)
        self.HomeLabel.textAlignment = .center
        self.view.addSubview(self.HomeLabel)
        
        self.VideoImageView = UIImageView()
        self.VideoImageView.frame = CGRectMake(0, 60, self.view.bounds.width, self.view.bounds.height - 60)
        self.view.addSubview(self.VideoImageView)
        
        self.DepthImageView = UIImageView()
        self.DepthImageView.frame = CGRectMake(0, 60, self.view.bounds.width, self.view.bounds.height - 60)
        self.DepthImageView.alpha = 1.0
        self.view.addSubview(self.DepthImageView)
        
        self.InitCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func InitCamera(){
        
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            self.Camera = dualCameraDevice
            print("DualCamera")
        }
        
        do {
            self.DeviceInput = try AVCaptureDeviceInput(device: self.Camera)
        } catch let error as NSError {
            print(error)
        }
        
        self.CaptureSession = AVCaptureSession()
        self.CaptureSession.sessionPreset = .photo
        
        self.CaptureSession.beginConfiguration()
        
        if (self.CaptureSession.canAddInput(self.DeviceInput)) {
            self.CaptureSession.addInput(DeviceInput)
        }
        
        let DepthOutputQueue = DispatchQueue(label: "DepthData Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
        
        self.DepthOutput = AVCaptureDepthDataOutput()
        self.PhotoOutput = AVCapturePhotoOutput()
        self.VideoOutput = AVCaptureVideoDataOutput()
        
        if (self.CaptureSession.canAddOutput(self.PhotoOutput)) {
            self.CaptureSession.addOutput(self.PhotoOutput)
        }
        
        if (self.PhotoOutput.isDepthDataDeliverySupported) {
            self.PhotoOutput.isDepthDataDeliveryEnabled = true
            self.DepthOutput.isFilteringEnabled = true
        }
        
        if (self.CaptureSession.canAddOutput(self.DepthOutput)) {
            self.CaptureSession.addOutput(self.DepthOutput)
            if let connection = self.DepthOutput.connection(with: .depthData) {
                connection.isEnabled = true
            } else {
                print("No AVCaptureConnection")
            }
        }
        
        if (self.CaptureSession.canAddOutput(self.VideoOutput)) {
            self.CaptureSession.addOutput(self.VideoOutput)
        }
        
        self.SyncOutput = AVCaptureDataOutputSynchronizer(dataOutputs: [self.VideoOutput, self.DepthOutput])
        self.CaptureSession.commitConfiguration()
        
        self.SyncOutput.setDelegate(self, queue: DepthOutputQueue)
        
        self.CaptureSession.startRunning()

    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func UIImageFromCMSamleBuffer(buffer: CMSampleBuffer)-> UIImage {
        // サンプルバッファからピクセルバッファを取り出す
        let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(buffer)!
        
        // ピクセルバッファをベースにCoreImageのCIImageオブジェクトを作成
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        //CIImageからCGImageを作成
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRectMake(0,0,pixelBufferWidth, pixelBufferHeight)
        let ciContext = CIContext.init()
        let cgimage = ciContext.createCGImage(ciImage, from: imageRect )
        
        // CGImageからUIImageを作成
        let image = UIImage(cgImage: cgimage!, scale: 1.0, orientation: UIImageOrientation.right)
        return image
    }
}

