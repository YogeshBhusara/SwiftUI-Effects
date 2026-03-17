import SwiftUI

struct LetterGlitchSettings: Equatable {
    var glitchSpeedMs: Double = 50
    var centerVignette: Bool = true
    var outerVignette: Bool = false
    var smooth: Bool = true
}

struct LetterGlitchEffectScreen: View {
    @State private var settings = LetterGlitchSettings()
    @State private var appliedSettings = LetterGlitchSettings()
    @State private var isPanelCollapsed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            LetterGlitchView(
                glitchSpeedMs: Int(appliedSettings.glitchSpeedMs),
                centerVignette: appliedSettings.centerVignette,
                outerVignette: appliedSettings.outerVignette,
                smooth: appliedSettings.smooth
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LetterGlitchControlsPanel(
                settings: $settings,
                appliedSettings: $appliedSettings,
                isCollapsed: $isPanelCollapsed
            )
            .frame(height: isPanelCollapsed ? 64 : 300)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct LetterGlitchControlsPanel: View {
    @Binding var settings: LetterGlitchSettings
    @Binding var appliedSettings: LetterGlitchSettings
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
                        Text("Controls")
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
                            title: "Glitch Speed (ms)",
                            value: $settings.glitchSpeedMs,
                            range: 10...200,
                            step: 5
                        )

                        Toggle("Smooth Color Transitions", isOn: $settings.smooth)
                            .toggleStyle(.switch)

                        Toggle("Center Vignette", isOn: $settings.centerVignette)
                            .toggleStyle(.switch)

                        Toggle("Outer Vignette", isOn: $settings.outerVignette)
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

