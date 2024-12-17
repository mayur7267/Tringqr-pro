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
            errorMessage = "No image selected."
            return
        }
        
       
        if let qrCode = extractQRCode(from: image) {
            scannedCode = qrCode
            errorMessage = nil
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
}


struct GIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // Perform GIF loading asynchronously
        DispatchQueue.global(qos: .userInteractive).async {
            if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let image = UIImage.animatedImage(withAnimatedGIFData: data)
                
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {}
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
