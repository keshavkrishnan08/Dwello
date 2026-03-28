import SwiftUI

struct HBTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.hbTextSecondary)

            HStack(spacing: HBSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.hbPrimary.opacity(0.5))
                        .frame(width: 20)
                }

                if isMultiline {
                    TextEditor(text: $text)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .keyboardType(keyboardType)
                }
            }
            .padding(HBSpacing.md)
            .background(Color.hbSurfaceWarm.opacity(0.5))
            .cornerRadius(HBRadii.input)
            .overlay(
                RoundedRectangle(cornerRadius: HBRadii.input)
                    .stroke(Color.hbBorder.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

struct HBCurrencyField: View {
    let title: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.hbTextSecondary)

            HStack(spacing: HBSpacing.sm) {
                Text("$")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.hbPrimary.opacity(0.6))

                TextField("0.00", text: $value)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .keyboardType(.decimalPad)
            }
            .padding(HBSpacing.md)
            .background(Color.hbSurfaceWarm.opacity(0.5))
            .cornerRadius(HBRadii.input)
            .overlay(
                RoundedRectangle(cornerRadius: HBRadii.input)
                    .stroke(Color.hbBorder.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack {
        HBTextField(title: "Title", text: .constant(""), placeholder: "What did you do?", icon: "wrench.fill")
        HBCurrencyField(title: "Cost", value: .constant(""))
    }
    .padding()
}
