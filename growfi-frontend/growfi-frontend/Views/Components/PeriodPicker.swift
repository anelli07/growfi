import SwiftUI

struct PeriodPicker: View {
    @Binding var selected: PeriodType
    @Binding var customRange: (Date, Date)?
    @Environment(\.presentationMode) var presentationMode
    @State private var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()
    @State private var showCustomPicker: Bool = false

    var body: some View {
        NavigationView {
            List {
                ForEach(PeriodType.allCases) { period in
                    HStack {
                        Text(period.rawValue)
                        Spacer()
                        if period == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selected = period
                        if period == .custom {
                            showCustomPicker = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                if showCustomPicker || selected == .custom {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Выберите период:")
                            .font(.subheadline)
                        DatePicker("Начало", selection: $customStart, displayedComponents: .date)
                        DatePicker("Конец", selection: $customEnd, in: customStart...Date.distantFuture, displayedComponents: .date)
                        Button("Сохранить") {
                            selected = .custom
                            customRange = (customStart, customEnd)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitle("Выбор периода", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            })
        }
    }
}

struct PeriodPicker_Previews: PreviewProvider {
    @State static var selected: PeriodType = .month
    @State static var customRange: (Date, Date)? = nil
    static var previews: some View {
        PeriodPicker(selected: $selected, customRange: $customRange)
    }
} 
