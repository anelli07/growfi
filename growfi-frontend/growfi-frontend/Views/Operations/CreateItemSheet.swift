import SwiftUI

struct CreateItemSheet: View {
    let type: OperationsView.CreateType
    var onCreate: (String, Double) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var sum: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Создать")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.top, 16)
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.blue)
                        .padding(.top, 16)
                }
            }
            Spacer().frame(height: 8)
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Название")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    TextField("Введите название", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(type == .wallet || type == .goal ? "Сумма (опционально)" : "Сумма")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    TextField("0", text: $sum)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
            Button(action: {
                let amount = Double(sum) ?? 0
                onCreate(name, amount)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Сохранить")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .disabled(name.isEmpty)
        }
        .background(Color.white)
        .cornerRadius(24)
        .ignoresSafeArea(edges: .bottom)
    }
} 