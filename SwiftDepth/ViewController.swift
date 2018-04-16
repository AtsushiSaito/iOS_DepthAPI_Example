//
//  ViewController.swift
//  SwiftDepth
//
//  Created by AtsushiSaito on 2018/04/12.
//  Copyright © 2018年 AtsushiSaito. All rights reserved.
//

import UIKit
import AVFoundation

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}

extension ViewController: AVCaptureDepthDataOutputDelegate {
    
}

extension ViewController: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        let DepthSyncData = synchronizedDataCollection.synchronizedData(for: self.DepthOutput) as? AVCaptureSynchronizedDepthData
        let DepthData = DepthSyncData?.depthData
        
        if (DepthData != nil){
            DispatchQueue.main.async {
                self.DepthImageView.image = self.ConvertDepthImage(DepthData: DepthData!)
            }
        }
        
        /*let VideoSyncData = synchronizedDataCollection.synchronizedData(for: self.VideoOutput) as? AVCaptureSynchronizedSampleBufferData
        let SampleBuffer = VideoSyncData?.sampleBuffer
        if (VideoSyncData?.sampleBufferWasDropped == false) {
            DispatchQueue.main.async {
                let Image = self.UIImageFromCMSamleBuffer(buffer: SampleBuffer!)
                self.VideoImageView.image = Image
            }
        } else {
            print("true")
        }*/
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
    
    let VideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
    let SessionQueue = DispatchQueue(label: "session queue", attributes: [], autoreleaseFrequency: .workItem)
    let DataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

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
        let interval = self.view.bounds.width / 3
        self.DepthImageView.frame = CGRectMake(0, 100, interval*3, interval*4)
        self.DepthImageView.alpha = 1.0
        self.view.addSubview(self.DepthImageView)
        
        SessionQueue.async {
            self.InitCamera()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func InitCamera(){
        self.CaptureSession = AVCaptureSession()
        self.DepthOutput = AVCaptureDepthDataOutput()
        self.PhotoOutput = AVCapturePhotoOutput()
        self.VideoOutput = AVCaptureVideoDataOutput()
        
        let DefaultVideoDevice: AVCaptureDevice? = VideoDeviceDiscoverySession.devices.first
        do {
            self.DeviceInput = try AVCaptureDeviceInput(device: DefaultVideoDevice!)
        } catch let error as NSError {
            print(error)
        }
        
        self.CaptureSession.beginConfiguration()
        self.CaptureSession.sessionPreset = .photo
        
        // Add a video input
        guard self.CaptureSession.canAddInput(self.DeviceInput) else {
            print("Could not add video device input to the session")
            self.CaptureSession.commitConfiguration()
            return
        }
        self.CaptureSession.addInput(self.DeviceInput)
        
        // Add a video data output
        if self.CaptureSession.canAddOutput(self.VideoOutput) {
            self.CaptureSession.addOutput(self.VideoOutput)
            self.VideoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.VideoOutput.setSampleBufferDelegate(self, queue: self.DataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            self.CaptureSession.commitConfiguration()
            return
        }
        
        if self.CaptureSession.canAddOutput(self.PhotoOutput) {
            self.CaptureSession.addOutput(self.PhotoOutput)
            
            self.PhotoOutput.isHighResolutionCaptureEnabled = true
            
            if self.PhotoOutput.isDepthDataDeliverySupported {
                self.PhotoOutput.isDepthDataDeliveryEnabled = true
            }
        } else {
            print("Could not add photo output to the session")
            self.CaptureSession.commitConfiguration()
            return
        }
        
        // Add a depth data output
        if self.CaptureSession.canAddOutput(self.DepthOutput) {
            self.CaptureSession.addOutput(self.DepthOutput)
            self.DepthOutput.setDelegate(self, callbackQueue: self.DataOutputQueue)
            //self.DepthOutput.isFilteringEnabled = true
            if let connection = self.DepthOutput.connection(with: .depthData) {
                connection.isEnabled = true
            } else {
                print("No AVCaptureConnection")
            }
        } else {
            print("Could not add depth data output to the session")
            self.CaptureSession.commitConfiguration()
            return
        }
        
        self.DepthOutput.connections[0].videoOrientation = .portrait
        self.SyncOutput = AVCaptureDataOutputSynchronizer(dataOutputs: [self.VideoOutput, self.DepthOutput])
        self.SyncOutput!.setDelegate(self, queue: self.DataOutputQueue)
        
        if self.PhotoOutput.isDepthDataDeliverySupported {
            if let frameDuration = DefaultVideoDevice?.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
                do {
                    try DefaultVideoDevice?.lockForConfiguration()
                    DefaultVideoDevice?.activeVideoMinFrameDuration = frameDuration
                    DefaultVideoDevice?.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
        
        self.CaptureSession.commitConfiguration()
        
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
        let cgimage = ciContext.createCGImage(ciImage, from: imageRect)
        
        // CGImageからUIImageを作成
        let image = UIImage(cgImage: cgimage!, scale: 1.0, orientation: UIImageOrientation.right)
        return image
    }
    
    func ConvertDepthImage(DepthData: AVDepthData) -> UIImage{
        let ConvertDepth = DepthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        let DepthMap: CVPixelBuffer = ConvertDepth.depthDataMap
        DepthMap.normalize()
        let DepthImage = CIImage(cvPixelBuffer: DepthMap)
        return UIImage(ciImage: DepthImage)
    }
}

