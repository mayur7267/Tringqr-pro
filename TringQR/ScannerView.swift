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
        VStack {
            Spacer(minLength: 0)

            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.95)
                        .frame(width: size.width, height: size.width)

                    ForEach(0...3, id: \.self) { index in
                        let rotation = Double(index) * 90
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                            .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .rotationEffect(.init(degrees: rotation))
                    }
                }
                .frame(width: size.width, height: size.width)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.blue.opacity(0.7))
                        .frame(height: 2.5)
                        .shadow(color: .black.opacity(0.7), radius: 8, x: 0, y: isScanning ? 15 : -15)
                        .offset(y: isScanning ? size.width : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 50)

            // Updated text position and content
            VStack {
                Text("Scan with TringQR")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                Text("World's fastest QR Code scanner")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.vertical, 10)

            Spacer()

            VStack {
                HStack(spacing: 4) { // Minimized spacing
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            updateZoomFactor(currentZoomFactor - 0.5) // Zoom out
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 14))
                            .padding(6)
                            .foregroundColor(.white)
                    }
                    
                    .disabled(currentZoomFactor <= 1.0)

                    Slider(
                        value: $currentZoomFactor,
                        in: 1.0...5.0
                    ) { isDragging in
                        
                        if !isDragging {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                updateZoomFactor(currentZoomFactor)
                            }
                        }
                    }
                    .onChange(of: currentZoomFactor) { newValue in
                        
                        updateZoomFactor(newValue)
                    }

                    .padding(.horizontal, 8)
                    .frame(height: 4)
                    .accentColor(.purple)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            updateZoomFactor(currentZoomFactor + 0.5) // Zoom in
                        }
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 14))
                            .padding(6)
                            .foregroundColor(.white)
                    }
                    
                    .disabled(currentZoomFactor >= 5.0)
                }
                .frame(maxWidth: 200)
                .padding(.vertical, 5)
            }

            HStack {
                // Gallery Button
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

                // Torch Button
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

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .padding(.vertical, 80)
        .onAppear(perform: checkCameraPermission)
        .alert(errormessage, isPresented: $showError) {
            if cameraPermission == .denied {
                Button("Settings") {
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingsURL = URL(string: settingsString) {
                        openURL(settingsURL)
                    }
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
                        
                       
                        appState.addScannedCode(code)
                        
                        handleScannedCode(code)
                        qrDelegate.scannedCode = nil 
                    }
                }
            }
    func reactivateCamera() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }

    func activateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)) {
            isScanning = true
        }
    }

    func deactivateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.85)) {
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
            lastZoomFactor = newZoomFactor
            device.unlockForConfiguration()
        } catch {
            presentError("Error applying zoom factor: \(error.localizedDescription)")
        }
    }

    func presentError(_ message: String) {
        errormessage = message
        showError.toggle()
    }

    private func handleImageFromGallery(_ image: UIImage?) {
        guard let image = image else {
            errorMessage = "No image selected."
            return
        }

        if let qrCode = extractQRCode(from: image) {
            scannedCode = qrCode
            errorMessage = nil
            handleScannedCode(qrCode)
        } else {
            errorMessage = "No QR code found in the image."
        }
    }

    private func extractQRCode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        return (features.first as? CIQRCodeFeature)?.messageString
    }

    private func handleScannedCode(_ code: String) {
        print("Scanned QR code: \(code)")

        if let url = URL(string: code), UIApplication.shared.canOpenURL(url) {
            openURL(url)
        } else {
            presentError("Scanned code is not a valid URL")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
