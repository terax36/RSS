import SwiftUI

enum Components {
    struct Badge: View {
        let text: String
        let color: Color

        var body: some View {
            Text(text)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .clipShape(Capsule())
        }
    }

    struct ProgressBar: View {
        let progress: Double

        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.secondary.opacity(0.2))
                    Capsule().fill(Color.accentColor)
                        .frame(width: proxy.size.width * max(0, min(1, progress)))
                }
            }
            .frame(height: 4)
        }
    }
}
