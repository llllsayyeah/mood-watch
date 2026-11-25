import SwiftUI

// MARK: - Card

struct CardBackground: ViewModifier {
    var padding: CGFloat = Theme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 0.5)
            )
            .shadow(color: Theme.cardShadow, radius: 12, x: 0, y: 8)
    }
}

extension View {
    func card(padding: CGFloat = Theme.cardPadding) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

// MARK: - Text pieces

/// 0.5pt separator that always uses the hairline token.
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 0.5)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cardTitle)
                    .foregroundStyle(Theme.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.captionText)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.captionText)
                    .foregroundStyle(Theme.inkTertiary)
            }
        }
    }
}

struct Pill: View {
    let text: String
    var tint: Color = Theme.mint
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(.tagText)
            .foregroundStyle(filled ? .white : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? tint : tint.opacity(0.14))
            )
    }
}

// MARK: - Rings

/// Thin ring used for habit progress.
struct MiniRing: View {
    let progress: Double
    var lineWidth: CGFloat = 5
    var size: CGFloat = 34
    var tint: Color = Theme.mint

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0.001, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

/// 270° gauge used on the Today page.
struct GaugeArc: View {
    let progress: Double
    var lineWidth: CGFloat = 22
    var tint: Color = Theme.mint

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Theme.surfaceAlt, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0, to: 0.75 * min(1, max(0.001, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [tint.opacity(0.65), tint]),
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(135 + 270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(135))
        }
    }
}

// MARK: - Charts

/// Smoothed line with an optional gradient fill, used for the intraday HRV curve.
struct SmoothLineShape: Shape {
    var points: [CGPoint]
    var closed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
        }
        if let last = points.last {
            path.addLine(to: last)
        }

        if closed, let first = points.first, let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: rect.maxY))
            path.addLine(to: CGPoint(x: first.x, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

struct Sparkline: View {
    let values: [Double]
    var tint: Color = Theme.mint
    var height: CGFloat = 60
    var showFill: Bool = true

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let minV = values.min(), let maxV = values.max() else { return [] }
        let span = max(0.001, maxV - minV)
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { idx, value in
            let x = CGFloat(idx) * stepX
            let ratio = (value - minV) / span
            let y = size.height - CGFloat(ratio) * (size.height - 8) - 4
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            ZStack {
                if showFill {
                    SmoothLineShape(points: pts, closed: true)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.28), tint.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                SmoothLineShape(points: pts, closed: false)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                if let lastPoint = pts.last {
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                        .position(lastPoint)
                }
            }
        }
        .frame(height: height)
    }
}

/// Rounded bar chart of daily levels.
struct LevelBarChart: View {
    let days: [DailyStress]
    var height: CGFloat = 190

    var body: some View {
        GeometryReader { geo in
            let items = days
            let count = max(1, items.count)
            let gap: CGFloat = count > 20 ? 2 : 6
            let barWidth = max(2, (geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count))
            let maxValue: Double = 100

            ZStack(alignment: .bottomLeading) {
                // Average guide line
                let avg = StressMath.mean(items.compactMap { $0.level == nil ? nil : $0.index })
                Path { p in
                    let y = geo.size.height - CGFloat(avg / maxValue) * geo.size.height
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(Theme.inkTertiary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(Array(items.enumerated()), id: \.element.date) { _, day in
                        let h = max(4, CGFloat(day.index / maxValue) * geo.size.height)
                        RoundedRectangle(cornerRadius: barWidth / 2.5, style: .continuous)
                            .fill((day.level?.color ?? Theme.muted).opacity(day.level == nil ? 0.35 : 0.9))
                            .frame(width: barWidth, height: h)
                    }
                }
                .frame(width: geo.size.width, alignment: .leading)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Small stat card

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    var series: [Double] = []
    var tint: Color = Theme.mint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.captionText)
                .foregroundStyle(Theme.inkSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text(unit)
                    .font(.captionText)
                    .foregroundStyle(Theme.inkTertiary)
            }
            if series.count > 1 {
                Sparkline(values: series, tint: tint, height: 34, showFill: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 16)
    }
}

// MARK: - Buttons

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.mint
    var filled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(filled ? .white : tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .fill(filled ? tint : tint.opacity(0.14))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
