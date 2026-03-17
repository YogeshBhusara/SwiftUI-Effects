import SwiftUI

struct DotGridSettings: Equatable {
    var dotSize: Double = 5
    var gap: Double = 15
    var proximity: Double = 120
    var shockRadius: Double = 250
    var shockStrength: Double = 5
    var resistance: Double = 750
    var returnDuration: Double = 1.5
}

struct DotGridEffectScreen: View {
    @State private var settings = DotGridSettings()
    @State private var appliedSettings = DotGridSettings()
    @State private var isPanelCollapsed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            DotGridView(
                dotSize: appliedSettings.dotSize,
                gap: appliedSettings.gap,
                baseColor: Color(red: 0.15, green: 0.12, blue: 0.22),
                activeColor: Color(red: 0.32, green: 0.15, blue: 1.0),
                proximity: appliedSettings.proximity,
                shockRadius: appliedSettings.shockRadius,
                shockStrength: appliedSettings.shockStrength,
                resistance: appliedSettings.resistance,
                returnDuration: appliedSettings.returnDuration
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            DotGridControlsPanel(
                settings: $settings,
                appliedSettings: $appliedSettings,
                isCollapsed: $isPanelCollapsed
            )
            .frame(height: isPanelCollapsed ? 64 : 320)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct DotGridControlsPanel: View {
    @Binding var settings: DotGridSettings
    @Binding var appliedSettings: DotGridSettings
    @Binding var isCollapsed: Bool

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
                        Text("Dot Grid")
                    }
                    .font(.headline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Apply") {
                    appliedSettings = settings
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
                            title: "Dot Size",
                            value: $settings.dotSize,
                            range: 2...10,
                            step: 0.5
                        )

                        EffectSlider(
                            title: "Gap",
                            value: $settings.gap,
                            range: 8...30,
                            step: 1
                        )

                        EffectSlider(
                            title: "Proximity",
                            value: $settings.proximity,
                            range: 40...200,
                            step: 5
                        )

                        EffectSlider(
                            title: "Shock Radius",
                            value: $settings.shockRadius,
                            range: 60...400,
                            step: 10
                        )

                        EffectSlider(
                            title: "Shock Strength",
                            value: $settings.shockStrength,
                            range: 1...10,
                            step: 0.5
                        )

                        EffectSlider(
                            title: "Resistance",
                            value: $settings.resistance,
                            range: 200...1500,
                            step: 50
                        )

                        EffectSlider(
                            title: "Return Duration",
                            value: $settings.returnDuration,
                            range: 0.3...3.0,
                            step: 0.1
                        )
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

