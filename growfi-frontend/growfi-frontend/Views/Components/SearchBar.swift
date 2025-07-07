import SwiftUI

struct SearchBar: View {
    var placeholder: String
    var onTap: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            Text(placeholder)
                .foregroundColor(.gray)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        //.shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
        //.padding(.horizontal, 16) // отступы от краёв экрана

    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(
            placeholder: "Поиск по примечаниям",
            onTap: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
