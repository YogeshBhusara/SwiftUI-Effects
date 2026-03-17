import SwiftUI

struct SlimeSettings: Equatable {
    var color: Color = .white
    var cursorBallColor: Color = .white
    var cursorBallSize: Double = 2.0
    var ballCount: Double = 15
    var animationSize: Double = 10
    var clumpFactor: Double = 0.7
    var speed: Double = 0.1
    var enableTransparency: Bool = true
    var hoverSmoothness: Double = 0.113
}

struct SlimeEffectScreen: View {
    @State private var settings = SlimeSettings()
    @State private var appliedSettings = SlimeSettings()
    @State private var isPanelCollapsed = false

    private let colorPresets: [Color] = [.white, .cyan, .pink, .yellow, .orange]

    var body: some View {
        ZStack(alignment: .bottom) {
            SlimeView(
                color: UIColor(appliedSettings.color),
                cursorBallColor: UIColor(appliedSettings.cursorBallColor),
                cursorBallSize: Float(appliedSettings.cursorBallSize),
                ballCount: Int(appliedSettings.ballCount),
                animationSize: Float(appliedSettings.animationSize),
                clumpFactor: Float(appliedSettings.clumpFactor),
                speed: Float(appliedSettings.speed),
                enableTransparency: appliedSettings.enableTransparency,
                hoverSmoothness: Float(appliedSettings.hoverSmoothness)
            )
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            SlimeControlsPanel(
                settings: $settings,
                appliedSettings: $appliedSettings,
                colorPresets: colorPresets,
                isCollapsed: $isPanelCollapsed
            )
            .frame(height: isPanelCollapsed ? 64 : 340)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct SlimeControlsPanel: View {
    @Binding var settings: SlimeSettings
    @Binding var appliedSettings: SlimeSettings
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
            .padding(.bottom, 2)

            Divider()
                .opacity(0.35)

            if !isCollapsed {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            Text("Color")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                ForEach(colorPresets, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle().stroke(
                                                Color.white.opacity(settings.color == color ? 1 : 0),
                                                lineWidth: 2
                                            )
                                        )
                                        .onTapGesture { settings.color = color }
                                }
                            }

                            Text("Cursor Color")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                ForEach(colorPresets, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle().stroke(
                                                Color.white.opacity(settings.cursorBallColor == color ? 1 : 0),
                                                lineWidth: 2
                                            )
                                        )
                                        .onTapGesture { settings.cursorBallColor = color }
                                }
                            }
                        }

                        EffectSlider(
                            title: "Ball Count",
                            value: $settings.ballCount,
                            range: 1...50,
                            step: 1
                        )

                        EffectSlider(
                            title: "Speed",
                            value: $settings.speed,
                            range: 0.01...1,
                            step: 0.01
                        )

                        EffectSlider(
                            title: "Clump Factor",
                            value: $settings.clumpFactor,
                            range: 0.3...1.5,
                            step: 0.01
                        )

                        EffectSlider(
                            title: "Animation Size",
                            value: $settings.animationSize,
                            range: 5...40,
                            step: 0.5
                        )

                        EffectSlider(
                            title: "Cursor Ball Size",
                            value: $settings.cursorBallSize,
                            range: 0.5...5,
                            step: 0.1
                        )

                        EffectSlider(
                            title: "Hover Smoothness",
                            value: $settings.hoverSmoothness,
                            range: 0.01...0.3,
                            step: 0.001
                        )

                        Toggle("Enable Transparency", isOn: $settings.enableTransparency)
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

struct EffectSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.3f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

