import SwiftUI

struct StartupIntroView: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)

                Text("NutriPlan")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Планирование питания без лишней рутины")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                carrotProgressBar
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                progress = 1
            }
        }
    }

    private var carrotProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 10)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.35),
                                Color.accentColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geometry.size.width * progress, 12), height: 10)

                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

                    Text("🥕")
                        .font(.system(size: 24))
                }
                .offset(
                    x: carrotOffset(in: geometry.size.width),
                    y: 0
                )
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 12)
    }

    private func carrotOffset(in width: CGFloat) -> CGFloat {
        max(0, min(width - 36, width * progress - 18))
    }
}
