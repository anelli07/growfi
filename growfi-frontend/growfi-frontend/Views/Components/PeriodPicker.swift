import SwiftUI

struct PeriodPicker: View {
    @Binding var selected: PeriodType
    @Environment(\.presentationMode) var presentationMode

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
                        presentationMode.wrappedValue.dismiss()
                    }
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
    static var previews: some View {
        PeriodPicker(selected: $selected)
    }
} 
