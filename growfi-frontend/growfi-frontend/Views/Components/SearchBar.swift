import SwiftUI

struct SearchBar: View {
    var placeholder: String
    @Binding var text: String
    var iconName: String? = nil // имя ассета
    var iconOnRight: Bool = false
    var body: some View {
        HStack(spacing: 8) {
            if !iconOnRight {
                if let iconName = iconName {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                }
            }
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.tail)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
            
            Spacer()
            if iconOnRight {
                if let iconName = iconName {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct SearchBar_Previews: PreviewProvider {
    @State static var text = ""
    static var previews: some View {
        SearchBar(
            placeholder: "Поиск по примечаниям",
            text: $text
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
