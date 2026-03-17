import SwiftUI

struct GradientGlassLinesSettings: Equatable {
    var gradientColors: [Color] = [Color(red: 1.0, green: 0.623, blue: 0.988), Color(red: 0.322, green: 0.153, blue: 1.0)]
    var angle: Double = 0
    var noise: Double = 0.3
    var blindCount: Double = 12
    var blindMinWidth: Double = 50
    var mouseDampening: Double = 0.15
    var mirrorGradient: Bool = false
    var spotlightRadius: Double = 0.5
    var spotlightSoftness: Double = 1.0
    var spotlightOpacity: Double = 1.0
    var distortAmount: Double = 0
    var shineDirectionIsRight: Bool = false
}

struct GradientGlassLinesEffectScreen: View {
    @State private var settings = GradientGlassLinesSettings()
    @State private var appliedSettings = GradientGlassLinesSettings()
    @State private var isPanelCollapsed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            GradientGlassLinesView(
                colors: appliedSettings.gradientColors.map { UIColor($0) },
                angle: Float(appliedSettings.angle * .pi / 180),
                noise: Float(appliedSettings.noise),
                blindCount: Int(appliedSettings.blindCount),
                blindMinWidth: Float(appliedSettings.blindMinWidth),
                mouseDampening: Float(appliedSettings.mouseDampening),
                mirrorGradient: appliedSettings.mirrorGradient,
                spotlightRadius: Float(appliedSettings.spotlightRadius),
                spotlightSoftness: Float(appliedSettings.spotlightSoftness),
                spotlightOpacity: Float(appliedSettings.spotlightOpacity),
                distortAmount: Float(appliedSettings.distortAmount),
                shineDirectionIsRight: appliedSettings.shineDirectionIsRight
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GradientGlassLinesControlsPanel(
                settings: $settings,
                appliedSettings: $appliedSettings,
                isCollapsed: $isPanelCollapsed
            )
            .frame(height: isPanelCollapsed ? 64 : 340)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct GradientGlassLinesControlsPanel: View {
    @Binding var settings: GradientGlassLinesSettings
    @Binding var appliedSettings: GradientGlassLinesSettings
    @Binding var isCollapsed: Bool

    private let colorPresets: [Color] = [
        Color(red: 1.0, green: 0.623, blue: 0.988),
        Color(red: 0.322, green: 0.153, blue: 1.0),
        .cyan,
        .mint,
        .orange,
        .yellow,
        .white
    ]

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
                        Text("Gradient Glass Lines")
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
                            Text("Gradient Colors")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Color 1")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack {
                                    ForEach(colorPresets, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle().stroke(
                                                    Color.white.opacity(settings.gradientColors.first == color ? 1 : 0),
                                                    lineWidth: 2
                                                )
                                            )
                                            .onTapGesture {
                                                if settings.gradientColors.isEmpty {
                                                    settings.gradientColors = [color]
                                                } else {
                                                    settings.gradientColors[0] = color
                                                }
                                            }
                                    }
                                }

                                Text("Color 2")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack {
                                    ForEach(colorPresets, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle().stroke(
                                                    Color.white.opacity(settings.gradientColors.count > 1 && settings.gradientColors[1] == color ? 1 : 0),
                                                    lineWidth: 2
                                                )
                                            )
                                            .onTapGesture {
                                                if settings.gradientColors.count < 2 {
                                                    if settings.gradientColors.isEmpty {
                                                        settings.gradientColors = [settings.gradientColors.first ?? color, color]
                                                    } else {
                                                        settings.gradientColors.append(color)
                                                    }
                                                } else {
                                                    settings.gradientColors[1] = color
                                                }
                                            }
                                    }
                                }
                            }
                        }

                        EffectSlider(
                            title: "Angle",
                            value: $settings.angle,
                            range: 0...360,
                            step: 1
                        )

                        EffectSlider(
                            title: "Noise",
                            value: $settings.noise,
                            range: 0...1,
                            step: 0.01
                        )

                        EffectSlider(
                            title: "Blind Count",
                            value: $settings.blindCount,
                            range: 2...64,
                            step: 1
                        )

                        EffectSlider(
                            title: "Min Blind Width",
                            value: $settings.blindMinWidth,
                            range: 10...200,
                            step: 1
                        )

                        EffectSlider(
                            title: "Spotlight Radius",
                            value: $settings.spotlightRadius,
                            range: 0.1...1.5,
                            step: 0.05
                        )

                        EffectSlider(
                            title: "Spotlight Softness",
                            value: $settings.spotlightSoftness,
                            range: 0.2...3,
                            step: 0.05
                        )

                        EffectSlider(
                            title: "Spotlight Opacity",
                            value: $settings.spotlightOpacity,
                            range: 0...2,
                            step: 0.05
                        )

                        EffectSlider(
                            title: "Distort Amount",
                            value: $settings.distortAmount,
                            range: 0...5,
                            step: 0.1
                        )

                        EffectSlider(
                            title: "Mouse Damping",
                            value: $settings.mouseDampening,
                            range: 0.01...0.5,
                            step: 0.01
                        )

                        Toggle("Mirror Gradient", isOn: $settings.mirrorGradient)

                        Toggle("Shine From Right", isOn: $settings.shineDirectionIsRight)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            panelShape
                .fill(.ultraThinMaterial)
                .background(
                    Color.white.opacity(0.05)
                        .blur(radius: 20)
                )
        )
        .overlay(
            panelShape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: 20)
    }
}

