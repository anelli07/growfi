import SwiftUI

struct CreateItemSheet: View {
    let type: OperationsView.CreateType
    var onCreate: (String, Double, String?, String?, String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var sum: String = ""
    @State private var selectedIcon: String = "creditcard.fill"
    @State private var selectedColor: Color = .blue
    @State private var selectedCurrency: String = "₸"
    let availableIcons = [
        "creditcard.fill", "banknote", "dollarsign.circle.fill", "wallet.pass.fill", "cart.fill", "gift.fill", "airplane", "car.fill", "cross.case.fill", "tshirt.fill", "scissors", "gamecontroller.fill", "cup.and.saucer.fill", "fork.knife", "phone.fill", "house.fill", "building.2.fill", "bag.fill", "star.fill", "questionmark.circle", "lipstick", "paintbrush.fill"
    ]
    let availableColors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .mint, .gray]
    let availableCurrencies = ["₸", "$", "€", "₽"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(type == .wallet ? "Новый кошелек" : "Создать")
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
            VStack(spacing: 8) {
                Text("Иконка")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                IconColorPickerView(
                    selectedIcon: $selectedIcon,
                    selectedColor: $selectedColor,
                    name: name,
                    availableIcons: availableIcons,
                    availableColors: availableColors
                )
            }
            .padding(.bottom, 8)
            .onAppear {
                switch type {
                case .income:
                    selectedIcon = "dollarsign.circle.fill"; selectedColor = .green
                case .wallet:
                    selectedIcon = "creditcard.fill"; selectedColor = .blue
                case .goal:
                    selectedIcon = "leaf.circle.fill"; selectedColor = .green
                case .expense:
                    selectedIcon = "cart.fill"; selectedColor = .red
                }
            }
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Название")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    TextField("Введите название", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                if type == .goal {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Желаемая сумма")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } else if type != .income {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type == .wallet ? "Сумма (опционально)" : "Сумма")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                if type != .income {
                    HStack {
                        Text("Валюта")
                            .font(.system(size: 16))
                        Spacer()
                        Picker("Валюта", selection: $selectedCurrency) {
                            ForEach(availableCurrencies, id: \.self) { currency in
                                Text(currency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
            Button(action: {
                let amount = Double(sum) ?? 0
                onCreate(name, amount, selectedIcon, selectedColor.toHex, selectedCurrency)
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

extension Color {
    var toHex: String? {
        UIColor(self).toHexString
    }
}

extension UIColor {
    var toHexString: String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
} 