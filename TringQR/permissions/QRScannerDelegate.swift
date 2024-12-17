//
//  QRScannerDelegate.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import AVKit
import AVFoundation

class QRScannerDelegate: NSObject,ObservableObject,AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metaobject = metadataObjects.first {
            guard let readableObject = metaobject as? AVMetadataMachineReadableCodeObject else { return }
            guard let Code = readableObject.stringValue else {return}
            print(Code)
            scannedCode = Code
        }
    }
   
}
