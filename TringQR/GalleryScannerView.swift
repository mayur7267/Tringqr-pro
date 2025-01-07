//
//  GalleryScannerView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import PhotosUI
import UIKit


struct PhotoPicker: UIViewControllerRepresentable {
   
    var onImageSelected: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onImageSelected: (UIImage?) -> Void

        init(onImageSelected: @escaping (UIImage?) -> Void) {
            self.onImageSelected = onImageSelected
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                onImageSelected(nil)
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self.onImageSelected(uiImage)
                    } else {
                        self.onImageSelected(nil)
                    }
                }
            }
        }
    }
}

struct GalleryScannerView: View {
    @EnvironmentObject var appState: AppState 
    @Binding var scannedCode: String
    @State private var isPickerPresented: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Button(action: { isPickerPresented = true }) {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.blue))
                    
                    Text("Scan from Gallery")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker { image in
                    handleImageFromGallery(image)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
    }

    private func handleImageFromGallery(_ image: UIImage?) {
        guard let image = image else {
            errorMessage = "Failed to load image from gallery."
            return
        }
        
        if let qrCode = extractQRCode(from: image) {
            scannedCode = qrCode
            errorMessage = nil

           
            appState.addScannedCode(
                qrCode,
                deviceId: appState.getDeviceId(),
                os: "iOS",
                event: "gallery_scan",
                eventName: "Gallery Scan"
            ) {
                print("Scanned code saved to history")
            }
        } else {
            errorMessage = "No QR code found in the selected image."
        }
    }

    private func extractQRCode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        return (features.first as? CIQRCodeFeature)?.messageString
    }
}


import SwiftUI
import UIKit

// GIFCache to store GIF data in memory
class GIFCache {
    static let shared = GIFCache()
    private let cache = NSCache<NSString, NSData>()
    
    func getCachedGIF(named name: String) -> Data? {
        return cache.object(forKey: name as NSString) as Data?
    }
    
    func cacheGIF(data: Data, named name: String) {
        cache.setObject(data as NSData, forKey: name as NSString)
    }
}

struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        // Load GIF
        loadGIF(for: imageView)

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

   
    private func loadGIF(for imageView: UIImageView) {
        DispatchQueue.global(qos: .userInteractive).async {
            // Check cache first
            if let cachedData = GIFCache.shared.getCachedGIF(named: gifName) {
                if let image = UIImage.animatedImage(withAnimatedGIFData: cachedData) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
                return
            }

            // Load from bundle if not cached
            guard let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                print("Error: GIF not found or failed to load: \(gifName)")
                return
            }

            // Cache and display the GIF
            GIFCache.shared.cacheGIF(data: data, named: gifName)
            if let image = UIImage.animatedImage(withAnimatedGIFData: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
    }
}



extension UIImage {
    static func animatedImage(withAnimatedGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        var images = [UIImage]()
        var duration: TimeInterval = 0
        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }
            let frameDuration = (CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any])
                .flatMap { $0[kCGImagePropertyGIFDictionary as String] as? [String: Any] }
                .flatMap { $0[kCGImagePropertyGIFDelayTime as String] as? TimeInterval } ?? 0.1
            duration += frameDuration
        }
        return UIImage.animatedImage(with: images, duration: duration)
    }
}
