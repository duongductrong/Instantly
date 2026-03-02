import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Decorative traffic lights
            HStack(spacing: 6) {
                Circle().fill(Color.red.opacity(0.85)).frame(width: 12, height: 12)
                Circle().fill(Color.yellow.opacity(0.85)).frame(width: 12, height: 12)
                Circle().fill(Color.green.opacity(0.85)).frame(width: 12, height: 12)
            }
            .padding(.leading, 16)

            Spacer()

            // Center branding
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Highlight AI")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text("|")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.3))

                Text("The AI Assistant")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Right action buttons
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))

                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.trailing, 16)
        }
        .frame(height: 44)
    }
}
