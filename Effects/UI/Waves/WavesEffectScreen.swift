import SwiftUI

struct WavesSettings: Equatable {
    var lineColor: Color = .white
    var backgroundOpacity: Double = 0.0
    var waveSpeedX: Double = 0.0125
    var waveSpeedY: Double = 0.01
    var waveAmpX: Double = 40
    var waveAmpY: Double = 20
    var friction: Double = 0.9
    var tension: Double = 0.01
    var maxCursorMove: Double = 120
    var xGap: Double = 12
    var yGap: Double = 36
}

struct WavesEffectScreen: View {
    @State private var settings = WavesSettings()
    @State private var appliedSettings = WavesSettings()

    private let colorPresets: [Color] = [.white, .cyan, .mint, .pink, .yellow]

    var body: some View {
        WavesRootView(
            settings: $settings,
            appliedSettings: $appliedSettings,
            colorPresets: colorPresets
        )
    }
}

private struct WavesRootView: View {
    @Binding var settings: WavesSettings
    @Binding var appliedSettings: WavesSettings
    let colorPresets: [Color]

    @State private var isPanelCollapsed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            let current = appliedSettings

            WavesView(
                lineColor: current.lineColor,
                backgroundColor: Color.white.opacity(current.backgroundOpacity),
                waveSpeedX: current.waveSpeedX,
                waveSpeedY: current.waveSpeedY,
                waveAmpX: current.waveAmpX,
                waveAmpY: current.waveAmpY,
                friction: current.friction,
                tension: current.tension,
                maxCursorMove: current.maxCursorMove,
                xGap: current.xGap,
                yGap: current.yGap
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            WavesControlsPanel(
                settings: $settings,
                appliedSettings: $appliedSettings,
                colorPresets: colorPresets,
                isCollapsed: $isPanelCollapsed
            )
            .frame(height: isPanelCollapsed ? 64 : 380)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct WavesControlsPanel: View {
    @Binding var settings: WavesSettings
    @Binding var appliedSettings: WavesSettings
    let colorPresets: [Color]
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
                        Text("Waves Controls")
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
            .padding(.bottom, 2)

            Divider()
                .opacity(0.35)

            if !isCollapsed {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Line Color")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                ForEach(colorPresets, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle().stroke(
                                                Color.white.opacity(settings.lineColor == color ? 1 : 0),
                                                lineWidth: 2
                                            )
                                        )
                                        .onTapGesture { settings.lineColor = color }
                                }
                            }

                            Text("Background")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            EffectSlider(
                                title: "Background Opacity",
                                value: $settings.backgroundOpacity,
                                range: 0...0.6,
                                step: 0.02
                            )
                        }

                        EffectSlider(
                            title: "Wave Speed X",
                            value: $settings.waveSpeedX,
                            range: 0.002...0.04,
                            step: 0.001
                        )

                        EffectSlider(
                            title: "Wave Speed Y",
                            value: $settings.waveSpeedY,
                            range: 0.002...0.04,
                            step: 0.001
                        )

                        EffectSlider(
                            title: "Amplitude X",
                            value: $settings.waveAmpX,
                            range: 5...80,
                            step: 1
                        )

                        EffectSlider(
                            title: "Amplitude Y",
                            value: $settings.waveAmpY,
                            range: 5...60,
                            step: 1
                        )

                        EffectSlider(
                            title: "Friction",
                            value: $settings.friction,
                            range: 0.7...0.98,
                            step: 0.005
                        )

                        EffectSlider(
                            title: "Tension",
                            value: $settings.tension,
                            range: 0.002...0.03,
                            step: 0.001
                        )

                        EffectSlider(
                            title: "Max Cursor Move",
                            value: $settings.maxCursorMove,
                            range: 40...200,
                            step: 5
                        )

                        EffectSlider(
                            title: "Grid X Gap",
                            value: $settings.xGap,
                            range: 6...30,
                            step: 1
                        )

                        EffectSlider(
                            title: "Grid Y Gap",
                            value: $settings.yGap,
                            range: 16...60,
                            step: 1
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

