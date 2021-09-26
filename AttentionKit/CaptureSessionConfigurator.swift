//
//  CaptureSessionConfigurator.swift
//  AttentionKit
//
//  Created by guillaume sabatié on 26/09/2021.
//

import Foundation
import AVKit
import Vision
import Combine


struct InputDevice {
    
}


class CaptureSessionConfigurator {
    enum error: Error {
        case executionError(NSError)
        case unknow
    }
    
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    // AVCaptureSession
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue

    var captureDevicePublisher = PassthroughSubject<(device: AVCaptureDevice, resolution: CGSize), CaptureSessionConfigurator.error>()

    init(videoDataOutputQueue: DispatchQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")) {
        self.videoDataOutputQueue = videoDataOutputQueue
    }
    
     func setupAVCaptureSession() -> AnyPublisher<(device: AVCaptureDevice, resolution: CGSize), CaptureSessionConfigurator.error> {
        let captureSession = AVCaptureSession()
        do {
            let inputDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: captureSession)
            //self.designatePreviewLayer(for: captureSession)
            //return captureSession
        } catch let executionError as NSError {
            return Fail<(device: AVCaptureDevice, resolution: CGSize),
                        CaptureSessionConfigurator.error>(
                error: .executionError(executionError))
                .eraseToAnyPublisher()
        } catch {
            Fail<(device: AVCaptureDevice, resolution: CGSize),
                 CaptureSessionConfigurator.error>(
                error: .unknow)
                .eraseToAnyPublisher()
        }
      // self.teardownAVCapture()
    }
    
    /// - Tag: CreateSerialDispatchQueue
    func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) -> AnyPublisher<(device: AVCaptureDevice, resolution: CGSize), CaptureSessionConfigurator.error> {

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.

        videoDataOutput.setSampleBufferDelegate(delegate, queue: videoDataOutputQueue)

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }

        videoDataOutput.connection(with: .video)?.isEnabled = true

        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }

        self.videoDataOutput = videoDataOutput


    }
    
    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)

        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }

                if let highestResolution = self.highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()

                    return (device, highestResolution.resolution)
                }
            }
        }

        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)

        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format

            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }

        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }

        return nil
    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
    }

}
