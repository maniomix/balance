import SwiftUI

// MARK: - PDF Export Placeholder (Web-based)

struct PDFExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var websiteURL = "https://balance-app.com/export"  // ← لینک رو بعداً عوض می‌کنی
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hexValue: 0x667EEA), Color(hexValue: 0x764BA2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, 10)
                
                // Title
                Text("Export PDF Report")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.Colors.text)
                
                // Description
                Text("Get your detailed financial report as PDF from our website")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Website Button
                Button {
                    if let url = URL(string: websiteURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                        
                        Text("Visit Website")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hexValue: 0x667EEA), Color(hexValue: 0x764BA2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .navigationTitle("PDF Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - در Insights View اینطوری استفاده کن:

/*
Button {
    showPDFExport = true
} label: {
    HStack {
        Image(systemName: "doc.text")
        Text("Export PDF")
    }
}
.sheet(isPresented: $showPDFExport) {
    PDFExportView()
}
*/
