//
//  ScannerView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import AVFoundation
import PhotosUI
import UIKit
import Firebase

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
        NavigationStack {
            GeometryReader { geometry in
                let _ = geometry.size.width
                let screenHeight = geometry.size.height
                let isCompactDevice = screenHeight < 700
                
                VStack {
                    Spacer(minLength: 0)
                    
                    GeometryReader { geometry in
                        let size = geometry.size
                        let scannerSize = max(isCompactDevice ? size.width - 20 : size.width, 320)
                        
                        ZStack {
                            CameraView(frameSize: CGSize(width: scannerSize, height: scannerSize), session: $session)
                                .frame(width: scannerSize, height: scannerSize)
                                .onAppear {
                                    let safeSize = max(scannerSize, 200)
                                    print("Scanner size updated to: \(safeSize)")
                                }
                            
                            ForEach(0...3, id: \.self) { index in
                                let rotation = Double(index) * 90
                                RoundedRectangle(cornerRadius: 11, style: .circular)
                                    .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                                    .rotationEffect(.init(degrees: rotation))
                            }
                        }
                        .frame(width: scannerSize, height: scannerSize)
                        .offset(y: isCompactDevice ? -50 : -92)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, isCompactDevice ? 25 : 38)
                    .edgesIgnoringSafeArea(.top)
                    
                    Spacer()
                    
                    VStack(spacing: isCompactDevice ? 8 : 12) {
                        Text("Scan with TringQR")
                            .font(isCompactDevice ? .title2 : .title)
                            .bold()
                            .foregroundStyle(.white)
                        Text("World's fastest QR Code scanner")
                            .font(isCompactDevice ? .body : .title3)
                            .bold()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .offset(y: isCompactDevice ? -35 : -90)
                    .padding(.vertical, 4)
                    
                    Spacer()
                    
                    VStack(spacing: isCompactDevice ? 5 : 10) {
                        HStack(spacing: 3) {
                            Button(action: {
                                updateZoomFactor(currentZoomFactor - 0.5)
                            }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.system(size: isCompactDevice ? 18 : 20))
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
                            .padding(.horizontal, isCompactDevice ? -30 : -45)
                            .frame(height: 4)
                            .accentColor(.purple)
                            .scaleEffect(x: 0.6, y: 0.6)
                            
                            Button(action: {
                                updateZoomFactor(currentZoomFactor + 0.5)
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.system(size: isCompactDevice ? 18 : 20))
                                    .padding(6)
                                    .foregroundColor(.white)
                            }
                            .disabled(currentZoomFactor >= 5.0)
                        }
                        .frame(maxWidth: 200)
                        .padding(.vertical, 5)
                        .offset(y: isCompactDevice ? -40 : -80)
                    }
                    
                    HStack {
                        Button(action: { isPickerPresented = true }) {
                            HStack(spacing: isCompactDevice ? 8 : 10) {
                                Image(systemName: "photo.circle.fill")
                                    .font(isCompactDevice ? .title3 : .title2)
                                    .foregroundColor(.black)
                                Text("Gallery")
                                    .font(isCompactDevice ? .callout : .headline)
                                    .foregroundColor(.black)
                            }
                        }
                        .sheet(isPresented: $isPickerPresented) {
                            PhotoPicker { image in
                                handleImageFromGallery(image)
                            }
                        }
                        
                        Divider()
                            .frame(height: isCompactDevice ? 25 : 30)
                            .background(Color.black)
                        
                        Button(action: toggleTorch) {
                            HStack(spacing: isCompactDevice ? 8 : 10) {
                                Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(isCompactDevice ? .body : .title3)
                                    .foregroundColor(.black)
                                Text("Light")
                                    .font(isCompactDevice ? .callout : .headline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal, isCompactDevice ? 15 : 20)
                    .padding(.vertical, isCompactDevice ? 10 : 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.yellow)
                    )
                    .shadow(radius: 5)
                    .offset(y: isCompactDevice ? -35 : -75)
                }
                .padding(.vertical, isCompactDevice ? 40 : 80)
            }
        }
        .onAppear {
            checkCameraPermission()
            activateScannerAnimation()
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
            
            appState.fetchScanHistory(deviceId: deviceId) { history in
                guard let history = history else {
                    print("No history found or an error occurred.")
                    return
                }
                
                let scannedItems = history.compactMap { item -> ScannedHistoryItem? in
                    guard let code = item["code"] as? String else { return nil }
                    return ScannedHistoryItem(
                        code: code,
                        eventName: item["eventName"] as? String,
                        event: item["event"] as? String,
                        timestamp: item["timestamp"] as? String
                    )
                }
                
                DispatchQueue.main.async {
                    appState.scannedHistory = scannedItems
                }
            }
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
                print("Scanned code detected: \(code)")
                scannedCode = code
                session.stopRunning()
                deactivateScannerAnimation()
                handleScannedCode(code)
                qrDelegate.scannedCode = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    restartScanning()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
        print("Handling scanned code: \(code)")
        let deviceId = appState.getDeviceId()
        let os = "ios"
        let event = "scan"
        let eventName = code

        print("Using deviceId: \(deviceId)")

       
        appState.addScannedCode(code, deviceId: deviceId, os: os, event: event, eventName: eventName) {
            print("Scan history updated for code: \(code)")

            
            if code.lowercased().hasPrefix("upi://pay") {
                print("Handling UPI QR code: \(code)")
                handleUPIQRCode(code)
            }
            
            else if let url = URL(string: code), UIApplication.shared.canOpenURL(url) {
                print("Handling regular URL-based code: \(code)")
                UIApplication.shared.open(url) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.restartScanning()
                    }
                }
            }
           
            else {
                print("Handling non-URL code: \(code)")
                let searchURLString = "https://www.google.com/search?q=\(code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                if let searchURL = URL(string: searchURLString) {
                    UIApplication.shared.open(searchURL) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.restartScanning()
                        }
                    }
                } else {
                    print("Failed to construct search URL for barcode: \(code)")
                }
            }
        }

       
        Analytics.logEvent("qr_code_scanned", parameters: [
            "code_type": code.contains("://") ? "url" : "text",
            "scan_method": "camera"
        ])
    }

   
    private func handleUPIQRCode(_ upiCode: String) {
        guard let components = URLComponents(string: upiCode),
              let queryItems = components.queryItems else {
            presentError("Invalid UPI QR code format")
            return
        }

       
        var mobikwikComponents = URLComponents()
        mobikwikComponents.scheme = "mobikwik"
        mobikwikComponents.host = "pay"

        
        var mobikwikQueryItems: [URLQueryItem] = []
        for item in queryItems {
            mobikwikQueryItems.append(URLQueryItem(name: item.name, value: item.value))
        }

        
        mobikwikQueryItems.append(URLQueryItem(name: "source", value: "upi_qr"))
        mobikwikComponents.queryItems = mobikwikQueryItems

        
        guard let mobikwikURL = mobikwikComponents.url else {
            presentError("Failed to create MobiKwik payment URL")
            return
        }

        print("Opening MobiKwik URL: \(mobikwikURL.absoluteString)")

        if UIApplication.shared.canOpenURL(mobikwikURL) {
            UIApplication.shared.open(mobikwikURL) { success in
                if !success {
                    self.presentError("Unable to open MobiKwik payment page")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.restartScanning()
                }
            }
        } else {
            promptToInstallMobiKwik()
        }
    }

   
    private func promptToInstallMobiKwik() {
        DispatchQueue.main.async {
            let installAlert = UIAlertController(
                title: "MobiKwik Required",
                message: "MobiKwik app is required for UPI payments. Would you like to install it?",
                preferredStyle: .alert
            )
            
            installAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.restartScanning()
            })
            
            installAlert.addAction(UIAlertAction(title: "Install", style: .default) { _ in
                if let appStoreURL = URL(string: "https://apps.apple.com/in/app/mobikwik-bhim-upi-wallet/id600002523") {
                    UIApplication.shared.open(appStoreURL) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.restartScanning()
                        }
                    }
                }
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(installAlert, animated: true)
            }
        }
    }
}

struct Preview_scannerview: PreviewProvider {
    static var previews: some View {
        ContentView(appState: AppState())
            .environmentObject(AppState())
            .previewDevice("iPhone SE (3rd generation)")
    }
}
