import SwiftUI

struct IconColorPickerView: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: Color
    let name: String
    let availableIcons: [String]
    let availableColors: [Color]
    
    @State private var showPicker = false
    @State private var wasManuallyPicked = false

    var body: some View {
        VStack(spacing: 8) {
            Button(action: { showPicker.toggle() }) {
                ZStack {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 80, height: 80)
                    Image(systemName: selectedIcon)
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: name) { newName in
                guard !wasManuallyPicked else { return }
                let type = CategoryType.from(name: newName)
                if type != .другое {
                    selectedIcon = type.icon
                    selectedColor = type.color
                }
            }
            if showPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.black.opacity(selectedColor == color ? 0.3 : 0), lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    wasManuallyPicked = true
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? selectedColor : Color(.systemGray5))
                                    .frame(width: 36, height: 36)
                                Image(systemName: icon)
                                    .foregroundColor(selectedIcon == icon ? .white : .gray)
                                    .font(.system(size: 20))
                            }
                            .onTapGesture {
                                selectedIcon = icon
                                wasManuallyPicked = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
} 