import SwiftUI

struct EffectsListView: View {
    private let effects: [EffectItem] = [
        EffectItem(type: .slime),
        EffectItem(type: .waves),
        EffectItem(type: .letterGlitch),
        EffectItem(type: .gravityBalloons),
        EffectItem(type: .dotGrid),
        EffectItem(type: .gradientGlassLines)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(effects) { item in
                        NavigationLink(value: item.type) {
                            EffectRowView(effectType: item.type)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Effects Showcase")
            .navigationDestination(for: EffectType.self) { effectType in
                EffectDetailView(effectType: effectType)
            }
        }
    }
}

struct EffectRowView: View {
    let effectType: EffectType

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(effectType.accentColor.opacity(0.2))
                Image(systemName: effectType.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(effectType.accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(effectType.displayName)
                    .font(.headline)
                Text(effectType.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

