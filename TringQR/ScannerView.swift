//
//  ScannerView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct ScannerView: View {
    @State private var isScanning: Bool = true
    @State private var session: AVCaptureSession = .init()
    @State private var cameraPermission: Permission = .idle
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    
    @State private var errormessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.openURL) private var openURL
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State private var isTorchOn: Bool = false
    
    @State private var currentZoomFactor: CGFloat = 1.0
    @State private var lastZoomFactor: CGFloat = 1.0
    @State private var isPickerPresented: Bool = false
    @State private var errorMessage: String?
    
    @EnvironmentObject var appState: AppState
    @State private var scannedCode: String = ""
    @State private var showGalleryPicker: Bool = false
 


    
    
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer(minLength: 0)
                
                GeometryReader { geometry in
                    let size = geometry.size
                    ZStack {
                        CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                            .frame(width: size.width, height: size.width)
                        
                        ForEach(0...3, id: \.self) { index in
                            let rotation = Double(index) * 90
                            RoundedRectangle(cornerRadius: 2, style: .circular)
                                .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                                .rotationEffect(.init(degrees: rotation))
                        }
                    }
                    .frame(width: size.width, height: size.width)
                    .offset(y:-92)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }
                .padding(.horizontal, 45)
                .edgesIgnoringSafeArea(.top)
                
                Spacer()
                VStack(spacing: 12) {
                    Text("Scan with TringQR")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                    Text("World's fastest QR Code scanner")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white.opacity(0.8))
                }
                .offset(y:-90)
                .padding(.vertical, 4)
                
                Spacer()
                
                VStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Button(action: {
                            updateZoomFactor(currentZoomFactor - 0.5)
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.system(size: 20))
                                .padding(6)
                                .foregroundColor(.white)
                        }
                        .disabled(currentZoomFactor <= 1.0)
                        
                        Slider(
                            value: $currentZoomFactor,
                            in: 1.0...5.0
                        ) { isDragging in
                            if !isDragging {
                                updateZoomFactor(currentZoomFactor)
                            }
                        }
                        .onChange(of: currentZoomFactor) { newValue in
                            updateZoomFactor(newValue)
                        }
                        .padding(.horizontal,-45)
                        .frame(height: 4)
                        .accentColor(.purple)
                        .scaleEffect(x: 0.6, y: 0.6)
                        
                        Button(action: {
                            updateZoomFactor(currentZoomFactor + 0.5)
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: 20))
                                .padding(6)
                                .foregroundColor(.white)
                        }
                        .disabled(currentZoomFactor >= 5.0)
                    }
                    .frame(maxWidth: 200)
                    .padding(.vertical, 5)
                    .offset(y:-80)
                }
                
                HStack {
                    Button(action: { isPickerPresented = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.circle.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                            Text("Gallery")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .sheet(isPresented: $isPickerPresented) {
                        PhotoPicker { image in
                            handleImageFromGallery(image)
                        }
                    }
                    
                    Divider()
                        .frame(height: 30)
                        .background(Color.black)
                    
                    Button(action: toggleTorch) {
                        HStack(spacing: 10) {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title3)
                                .foregroundColor(.black)
                            Text("Light")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.yellow)
                )
                .shadow(radius: 5)
                .offset(y:-75)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .padding(.vertical, 80)
            
        }
        .onAppear {
            checkCameraPermission()
            activateScannerAnimation()
        }
        .onDisappear {
            session.stopRunning()
            deactivateScannerAnimation()
        }
        
        
        .alert(errormessage, isPresented: $showError) {
            if cameraPermission == .denied {
                Button("Settings") {
                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onChange(of: cameraPermission) { newPermission in
            if newPermission == .approved {
                reactivateCamera()
            }
        }
        .onChange(of: qrDelegate.scannedCode) { newValue in
            if let code = newValue {
                scannedCode = code
                session.stopRunning()
                deactivateScannerAnimation()

                
                let deviceId = "device-unique-id-123"
                let userId = "user-id-456"  
                
                appState.addScannedCode(code, deviceId: deviceId, userId: userId)
                handleScannedCode(code)
                
                qrDelegate.scannedCode = nil
                
                // Restart scanning after processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    restartScanning()
                }
            }
        }
    }
    func restartScanning() {
        DispatchQueue.global(qos: .background).async {
            if !session.isRunning {
                session.startRunning()
                DispatchQueue.main.async {
                    activateScannerAnimation()
                }
            }
        }
    }
    
    func reactivateCamera() {
        DispatchQueue.global(qos: .background).async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }
    
    func activateScannerAnimation() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isScanning = true
            }
        }
    }
    
    func deactivateScannerAnimation() {
        DispatchQueue.main.async {
            isScanning = false
        }
    }
    
    
    func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty {
                    setupCamera()
                } else {
                    session.startRunning()
                }
            case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video) {
                    cameraPermission = .approved
                    setupCamera()
                } else {
                    cameraPermission = .denied
                    presentError("Please provide access to the camera for scanning codes")
                }
            case .denied, .restricted:
                cameraPermission = .denied
                presentError("Please provide access to the camera for scanning codes")
            default:
                break
            }
        }
    }
    
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if isTorchOn {
                    device.torchMode = .off
                } else {
                    try device.setTorchModeOn(level: 1.0)
                }
                
                isTorchOn.toggle()
                device.unlockForConfiguration()
            } catch {
                presentError("Torch could not be used: \(error.localizedDescription)")
            }
        } else {
            presentError("Torch is not available on this device")
        }
    }
    
    func setupCamera() {
        do {
            
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
                presentError("No camera found")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("Cannot add input or output")
                return
            }
            
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            qrOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .code128, .pdf417, .code39, .code93, .code39Mod43]
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
            activateScannerAnimation()
            
        } catch {
            presentError("Failed to set up camera: \(error.localizedDescription)")
        }
    }
    
    
    func updateZoomFactor(_ factor: CGFloat) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            let newZoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            device.videoZoomFactor = newZoomFactor
            currentZoomFactor = newZoomFactor
            device.unlockForConfiguration()
        } catch {
            presentError("Zoom error: \(error.localizedDescription)")
        }
    }
    
    func presentError(_ message: String) {
        errormessage = message
        showError.toggle()
    }
    
    func handleImageFromGallery(_ image: UIImage?) {
        guard let image = image else {
            errorMessage = "No image selected."
            return
        }
        
        if let qrCode = extractQRCode(from: image) {
            scannedCode = qrCode
            handleScannedCode(qrCode)
        } else {
            errorMessage = "No QR code found in the image."
        }
    }
    
    
    func extractQRCode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        return (features.first as? CIQRCodeFeature)?.messageString
    }
    func handleScannedCode(_ code: String) {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
        let userId = "unknown-user-id"




        appState.addScannedCode(code, deviceId: deviceId, userId: userId)

        guard let url = URL(string: code) else {
            presentError("Invalid QR code content: \(code)")
            return
        }

        if code.lowercased().hasPrefix("upi://pay") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        presentError("Unable to open UPI link. Please ensure a UPI app is installed.")
                    }
                }
            } else {
                presentError("No app available to handle UPI payment.")
            }
        } else {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                presentError("Scanned code is not a valid URL: \(code)")
            }
        }
    }

}

#Preview {
    ContentView(appState: AppState())
        .environmentObject(AppState())
}

