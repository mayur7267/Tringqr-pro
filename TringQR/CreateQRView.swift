//
//   CreateQRView.swift
//  TringQR
//
//  Created by Mayur on 07/01/25.
//
import SwiftUI
import CoreImage.CIFilterBuiltins

struct CreateQRView: View {
    @EnvironmentObject var appState: AppState
    @State private var qrText: String = "http://"
    @State private var qrImage: UIImage?
    @Binding var selectedTab: Int
    @Binding var isBackButtonVisible: Bool
    @FocusState private var isTextFieldFocused: Bool
    @State private var showToast: Bool = false
    @State private var currentTab: String = "Create"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
               
                HStack {
                    Button(action: {
                        withAnimation {
                            selectedTab = 1
                            isBackButtonVisible = false
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .imageScale(.large)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    Text("Create QR")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .foregroundColor(.clear)
                        .imageScale(.large)
                        .padding(.trailing, 10)
                }
                .padding(.vertical, 10)
                .background(Color.yellow)
                
               
                HStack(spacing: 0) {
                    ForEach(["History", "Create"], id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                currentTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(tab)
                                    .foregroundColor(currentTab == tab ? .purple : .gray)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                
                                Rectangle()
                                    .fill(currentTab == tab ? Color.purple : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.white)
                
                
                if currentTab == "Create" {
                    createContent
                } else {
                    historyContent
                }
                
                if showToast {
                    ToastView()
                        .padding(.bottom, 30)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showToast)
                }
            }
            .offset(y: 40)
            .preferredColorScheme(.light)
        }
    }
    
   
    private var createContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    TextField("Enter URL", text: $qrText)
                        .keyboardType(.URL)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                            )
                        .focused($isTextFieldFocused)
                        .onTapGesture {
                            if qrText == "http://" {
                                qrText = ""
                            }
                        }
                    
                    Button(action: pasteFromClipboard) {
                        Image(systemName: "doc.on.clipboard")
                            .padding(10)
                            .foregroundStyle(.black)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                    }
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
                                .foregroundStyle(.black)
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
                    qrImageView(qrImage)
                }
                
                Spacer()
            }
            .padding(.top)
        }
    }
    
    
    private var historyContent: some View {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(appState.qrHistory.reversed()) { item in
                        HStack {
                            Text(item.content)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .padding(.leading)
                            
                            Spacer()
                            
                            if let image = item.image {
                                Button(action: { downloadQRCode(image) }) {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                }
                                
                                Button(action: { shareQRCode(image) }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.trailing, 4)
                                }
                            }
                        }
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .shadow(color: .gray.opacity(0.1), radius: 2)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
    private func qrImageView(_ image: UIImage) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // QR Code
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                
               
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal)
                
                
                HStack(spacing: 20) {
                    Button(action: { downloadQRCode(image) }) {
                        Text("Download")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(10)
                            .frame(width: 120)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { shareQRCode(image) }) {
                        Text("Share")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(10)
                            .frame(width: 120)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 15)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.1), radius: 2)
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
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
                    
                    
                    appState.addQRCode(qrText, image: qrImage) {
                        
                    }
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
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
    private func shareQRCode(_ image: UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}

struct ToastView: View {
    var body: some View {
        Text("Saved successfully!")
            .font(.subheadline)
            .padding()
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

#Preview {
    CreateQRView(selectedTab: .constant(4), isBackButtonVisible: .constant(false))
}
