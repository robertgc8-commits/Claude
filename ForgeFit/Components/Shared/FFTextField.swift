import SwiftUI

struct FFTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var leadingIcon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.ffSubtext)
                    .frame(width: 20)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(size: 16))
        .foregroundStyle(Color.ffText)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.ffSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.ffBorder, lineWidth: 1)
        )
    }
}
