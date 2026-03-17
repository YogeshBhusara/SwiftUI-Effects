import SwiftUI

struct GravityBalloonsSettings: Equatable {
    var count: Double = 80
    var gravity: Double = 0.08
    var friction: Double = 0.995
    var wallBounce: Double = 0.9
    var followCursor: Bool = false
}

struct GravityBalloonsEffectScreen: View {
    @State private var settings = GravityBalloonsSettings()
    @State private var appliedSettings = GravityBalloonsSettings()
    @State private var resetKey: Int = 0
    @State private var isPanelCollapsed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            GravityBalloonsView(
                count: Int(appliedSettings.count),
                gravity: appliedSettings.gravity,
                friction: appliedSettings.friction,
                wallBounce: appliedSettings.wallBounce,
                followCursor: appliedSettings.followCursor,
                resetKey: resetKey
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GravityBalloonsControlsPanel(
                settings: $settings,
                appliedSettings: $appliedSettings,
                isCollapsed: $isPanelCollapsed,
                onApply: {
                    appliedSettings = settings
                    resetKey &+= 1
                }
            )
            .frame(height: isPanelCollapsed ? 64 : 320)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct GravityBalloonsControlsPanel: View {
    @Binding var settings: GravityBalloonsSettings
    @Binding var appliedSettings: GravityBalloonsSettings
    @Binding var isCollapsed: Bool
    var onApply: () -> Void

    var body: some View {
        let panelShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isCollapsed.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                        Text("Gravity Balloons")
                    }
                    .font(.headline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Apply") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(appliedSettings == settings)
            }

            Divider()
                .opacity(0.35)

            if !isCollapsed {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        EffectSlider(
                            title: "Balloon Count",
                            value: $settings.count,
                            range: 10...150,
                            step: 1
                        )

                        EffectSlider(
                            title: "Gravity",
                            value: $settings.gravity,
                            range: 0.01...0.3,
                            step: 0.01
                        )

                        EffectSlider(
                            title: "Friction",
                            value: $settings.friction,
                            range: 0.96...0.999,
                            step: 0.001
                        )

                        EffectSlider(
                            title: "Wall Bounce",
                            value: $settings.wallBounce,
                            range: 0.6...1.1,
                            step: 0.02
                        )

                        Toggle("Follow Cursor", isOn: $settings.followCursor)
                            .toggleStyle(.switch)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 30, x: 0, y: 18)
    }
}

