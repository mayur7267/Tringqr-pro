//
//   CreateQRView.swift
//  TringQR
//
//  Created by Mayur on 07/01/25.
//
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRHistoryItem: Identifiable {
    let id = UUID()
    let text: String
    let image: UIImage
}

struct CreateQRView: View {
    @State private var qrText: String = "http://"
    @State private var qrImage: UIImage?
    @State private var selectedTab: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    @State private var qrHistory: [QRHistoryItem] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { selectedTab = 0; hideKeyboard() }) {
                        Text("History")
                            .font(.subheadline)
                            .foregroundColor(selectedTab == 0 ? .purple : .gray)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == 0 ? Color.gray.opacity(0.1) : Color.clear)
                    }

                    Button(action: { selectedTab = 1; hideKeyboard() }) {
                        Text("Create")
                            .font(.subheadline)
                            .foregroundColor(selectedTab == 1 ? .purple : .gray)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == 1 ? Color.gray.opacity(0.1) : Color.clear)
                    }
                }
                .background(Color.gray.opacity(0.2))

                if selectedTab == 0 {
                    if qrHistory.isEmpty {
                        VStack {
                            Text("History")
                                .font(.headline)
                                .padding()
                            Text("No QR codes created yet.")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.9))
                    } else {
                        List {
                            ForEach(qrHistory) { item in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(item.text)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Image(uiImage: item.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                    
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            shareQRCode(item.image)
                                        }) {
                                            Text("Share")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                                .padding(10)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        }

                                        Button(action: {
                                            downloadQRCode(item.image)
                                        }) {
                                            Text("Download")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                                .padding(10)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        }

                                        Button(action: {
                                            deleteQRCode(item.id)
                                        }) {
                                            Text("Delete")
                                                .font(.subheadline)
                                                .foregroundColor(.red)
                                                .padding(10)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .background(Color.white.opacity(0.9))
                    }
                } else {
                    Spacer()
                    Spacer()
                    VStack(spacing: 20) {
                        HStack {
                            TextField("Enter URL", text: $qrText)
                                .keyboardType(.URL)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .focused($isTextFieldFocused)
                                .foregroundColor(.primary)
                                .onTapGesture {
                                    if qrText == "http://" {
                                        qrText = ""
                                    }
                                }

                            Button(action: pasteFromClipboard) {
                                Image(systemName: "doc.on.clipboard")
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.primary)
                            }
                            .disabled(qrText.isEmpty)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 15) {
                            ForEach(["www.", ".com", ".in", ".ai", ".tech"], id: \.self) { suffix in
                                Button(action: {
                                    qrText += suffix
                                }) {
                                    Text(suffix)
                                        .font(.subheadline)
                                        .padding(8)
                                        .foregroundColor(.primary)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(5)
                                }
                            }
                        }
                        .padding(.horizontal)

                        Button(action: generateQRCode) {
                            Text("Create QR")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                        }
                        .padding()
                        .disabled(qrText.isEmpty)

                        if let qrImage = qrImage {
                            VStack {
                                Image(uiImage: qrImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300)
                                    .padding()

                                HStack(spacing: 20) {
                                    Button(action: {
                                        downloadQRCode(qrImage)
                                    }) {
                                        Text("Download")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .padding(10)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }

                                    Button(action: {
                                        shareQRCode(qrImage)
                                    }) {
                                        Text("Share")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .padding(10)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.bottom)
                            }
                            .padding()
                        }

                        Spacer()
                    }
                    .background(Color.white.opacity(0.9))
                }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .top)
            .background(Color.white.opacity(0.9))
        }
        .preferredColorScheme(.light)
    }

    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        let data = Data(qrText.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let qrImage = UIImage(cgImage: cgimg)
                self.qrImage = qrImage
                
                let historyItem = QRHistoryItem(text: qrText, image: qrImage)
                qrHistory.append(historyItem)
            }
        }
    }

    private func pasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            qrText = clipboardText
        }
    }

    private func downloadQRCode(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func shareQRCode(_ image: UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func deleteQRCode(_ id: UUID) {
        qrHistory.removeAll { $0.id == id }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    CreateQRView()
}
