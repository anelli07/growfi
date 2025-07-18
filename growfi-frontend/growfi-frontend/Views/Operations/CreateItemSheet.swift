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
    
    init(type: OperationsView.CreateType, onCreate: @escaping (String, Double, String?, String?, String) -> Void) {
        self.type = type
        self.onCreate = onCreate
        
        // Инициализируем @State переменные в зависимости от типа
        let (icon, color) = Self.getDefaultIconAndColor(for: type)
        _selectedIcon = State(initialValue: icon)
        _selectedColor = State(initialValue: color)
    }
    
    private static func getDefaultIconAndColor(for type: OperationsView.CreateType) -> (String, Color) {
        switch type {
        case .income:
            return ("dollarsign.circle.fill", .green)
        case .wallet:
            return ("creditcard.fill", .blue)
        case .goal:
            return ("leaf.circle.fill", .green)
        case .expense:
            return ("wallet.pass.fill", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(type == .wallet ? "create_wallet_title".localized : "create_title".localized)
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
                Text("icon".localized)
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
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("name".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    TextField("enter_name".localized, text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                if type == .goal {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("goal_amount".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } else if type == .wallet {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("wallet_amount_optional".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                if type == .goal || type == .wallet {
                    HStack {
                        Text("currency".localized)
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
                let amount: Double = (type == .goal || type == .wallet) ? (Double(sum) ?? 0) : 0
                let finalName = name.isEmpty ? defaultName.localizedIfDefault : name
                onCreate(finalName, amount, selectedIcon, selectedColor.toHex, selectedCurrency)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("save".localized)
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
    
    // Добавляю вычисляемое свойство для дефолтного имени
    private var defaultName: String {
        switch type {
        case .income: return "Income"
        case .wallet: return "Wallet"
        case .goal: return "Goal"
        case .expense: return "Expense"
        }
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