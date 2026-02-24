import SwiftUI
import CoreImage.CIFilterBuiltins

struct GroupCodeHeader: View {
    let groupId: String
    
    @State private var showQRCode = false
    @State private var codeCopied = false
    
    var body: some View {
        HStack(spacing: 16) {
            Text("Code:")
                .foregroundStyle(.gray)
                .font(.subheadline)
            
            Text(groupId)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            Button {
                showQRCode = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "qrcode")
                    Text("QR Code")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.green)
            }
            
            Button {
                UIPasteboard.general.string = groupId
                withAnimation { codeCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { codeCopied = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: codeCopied ? "checkmark.doc.fill" : "doc.on.doc")
                    Text(codeCopied ? "Copied" : "Copy")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
            }
        }
        .padding(.bottom, 16)
        .sheet(isPresented: $showQRCode) {
            QRCodeSheet(code: groupId)
        }
    }
}

// MARK: - QR Code Sheet

struct QRCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                    }
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Scan to Join Group")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("Point your camera at this QR code\nto instantly join the poker group.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        
                    Image(uiImage: generateQRCode(from: code))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.top, 24)
                        
                    Text(code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.accent)
                        .kerning(4)
                        .padding(.top, 16)
                }
                
                Spacer()
                Spacer()
            }
        }
    }
    
    // Uses CoreImage built-in QR Code Generator for crisp rendering without third-party frameworks.
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

#Preview {
    GroupCodeHeader(groupId: "123ABC_TEST")
}
