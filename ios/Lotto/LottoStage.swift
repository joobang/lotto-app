import SwiftUI

struct LottoStage: View {
    let numbers: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("LOTTO  6 / 45")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .tracking(3)
                Spacer()
                Image(systemName: "sparkle").font(.system(size: 19, weight: .light))
            }.foregroundStyle(LottoStyle.lime.opacity(0.9))

            Text(numbers.isEmpty ? "오늘의\n조합" : "오늘의\n여섯 번호")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .tracking(-1)
                .foregroundStyle(.white)

            Spacer(minLength: 8)

            if numbers.isEmpty {
                HStack(spacing: 7) {
                    ForEach(0..<6, id: \.self) { _ in
                        Circle().fill(.white.opacity(0.09))
                            .overlay(Circle().strokeBorder(.white.opacity(0.28)))
                            .overlay(Text("·").font(.title2.weight(.black)).foregroundStyle(.white.opacity(0.7)))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }.accessibilityHidden(true)
            } else {
                BallRow(numbers: numbers, stage: true)
                    .shadow(color: LottoStyle.lime.opacity(0.13), radius: 5)
                    .accessibilityIdentifier("draw-result")
            }
        }
        .padding(23)
        .frame(minHeight: 354)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 30).fill(LottoStyle.night)
            RoundedRectangle(cornerRadius: 30).fill(
                RadialGradient(colors: [LottoStyle.violet.opacity(0.72), .clear],
                               center: .bottomTrailing, startRadius: 4, endRadius: 320))
            GeometryReader { bounds in
                StageOrbits()
                StageOrb()
                    .frame(width: bounds.size.width * 0.46, height: bounds.size.width * 0.46)
                    .position(x: bounds.size.width * 0.72, y: bounds.size.height * 0.48)
            }.clipShape(RoundedRectangle(cornerRadius: 30))
        }
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.14)))
        .shadow(color: LottoStyle.night.opacity(0.18), radius: 19, y: 10)
    }
}

private struct StageOrbits: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<8 {
                let offset = Double(index) * 13
                let rect = CGRect(x: size.width * 0.43 - offset, y: -130 + offset,
                                  width: size.width * 0.94 + offset, height: size.height + 138 - offset)
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.10)), lineWidth: 1)
            }
            for index in 0..<31 {
                let x = Double((index * 71 + 18) % 337) / 337 * size.width
                let y = Double((index * 47 + 13) % 211) / 211 * size.height
                let diameter = index % 6 == 0 ? 3.4 : 1.6
                let dot = CGRect(x: x, y: y, width: diameter, height: diameter)
                context.fill(Path(ellipseIn: dot), with: .color(
                    (index % 6 == 0 ? LottoStyle.lime : .white).opacity(0.34)))
            }
        }.accessibilityHidden(true)
    }
}

private struct StageOrb: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [
                    Color(red: 0.89, green: 0.84, blue: 1),
                    Color(red: 0.58, green: 0.47, blue: 0.94),
                    Color(red: 0.34, green: 0.22, blue: 0.68),
                    Color(red: 0.15, green: 0.10, blue: 0.38)
                ], center: .topLeading, startRadius: 6, endRadius: 164))
                .shadow(color: .purple.opacity(0.42), radius: 25)
                .overlay(Circle().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.04), .white.opacity(0.56)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            Ellipse().fill(.white.opacity(0.34))
                .frame(width: 49, height: 13).blur(radius: 6)
                .rotationEffect(.degrees(-23)).offset(x: -32, y: -48)
            Image(systemName: "sparkle")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(LottoStyle.lime.opacity(0.94))
                .shadow(color: LottoStyle.lime.opacity(0.35), radius: 14)
        }
        .rotationEffect(.degrees(11))
        .accessibilityHidden(true)
    }
}

struct DrawReveal: Identifiable {
    let id = UUID()
    let start = Date()
    let numbers: [Int]
    let title: String
}

struct LottoCutscene: View {
    static let duration = 0.82
    let reveal: DrawReveal

    var body: some View {
        TimelineView(.animation) { time in
            let elapsed = max(0, time.date.timeIntervalSince(reveal.start))
            let phase = min(1, elapsed / Self.duration)
            let exit = max(0, (phase - 0.70) / 0.30)
            GeometryReader { screen in
                let center = CGPoint(x: screen.size.width / 2, y: screen.size.height * 0.49)
                ZStack {
                    RadialGradient(colors: [
                        Color(red: 0.29, green: 0.12, blue: 0.50),
                        Color(red: 0.10, green: 0.04, blue: 0.23),
                        Color(red: 0.027, green: 0.018, blue: 0.065)
                    ], center: UnitPoint(x: 0.5, y: 0.49), startRadius: 2,
                        endRadius: max(screen.size.width, screen.size.height) * 0.56)

                    CutsceneLight(phase: phase)

                    VStack(spacing: 14) {
                        Text("LOTTO   6 / 45")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .tracking(5)
                            .foregroundStyle(LottoStyle.lime)
                        Text(reveal.title)
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                        BallRow(numbers: reveal.numbers, stage: true)
                            .shadow(color: Color(red: 0.89, green: 0.70, blue: 1).opacity(0.6), radius: 13)
                            .padding(.top, 5)
                    }
                    .frame(width: screen.size.width * 0.90)
                    .scaleEffect(0.91 + 0.09 * (1 - exp(-phase * 24)))
                    .position(center)
                }
                .opacity(1 - exit * exit)
            }
        }
        .ignoresSafeArea()
    }
}

private struct CutsceneLight: View {
    let phase: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.49)
            let burst = 1 - pow(1 - phase, 3)
            let lavender = Color(red: 0.77, green: 0.52, blue: 1)
            let mint = LottoStyle.lime
            let radius = size.width * (0.36 + 0.11 * burst)

            for index in 0..<7 {
                let ringRadius = radius + Double(index) * 6
                let angle = Double(index) * 32 + 40 * burst
                var ring = context
                ring.translateBy(x: center.x, y: center.y)
                ring.rotate(by: .degrees(angle))
                let ellipse = CGRect(x: -ringRadius, y: -ringRadius * 0.67,
                                     width: ringRadius * 2, height: ringRadius * 1.34)
                ring.stroke(
                    Path(ellipseIn: ellipse),
                    with: .linearGradient(
                        Gradient(colors: [.clear, lavender.opacity(0.64), mint.opacity(index.isMultiple(of: 3) ? 0.67 : 0.18), .clear]),
                        startPoint: CGPoint(x: ellipse.minX, y: ellipse.minY),
                        endPoint: CGPoint(x: ellipse.maxX, y: ellipse.maxY)
                    ), lineWidth: index.isMultiple(of: 3) ? 1.5 : 0.65
                )
            }

            for index in 0..<68 {
                let angle = Double(index) * 2.39996
                let strength = Double((index * 41) % 89) / 89
                let scale = 0.34 + strength * 0.69 + burst * (0.3 + strength)
                let distance = size.width * scale
                let tail = 5 + strength * 30 * (1 - phase)
                let tint = index.isMultiple(of: 5) ? mint : lavender
                let alpha = 0.22 + 0.61 * strength * (1 - phase * 0.65)
                let tip = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
                let origin = CGPoint(x: tip.x - cos(angle) * tail, y: tip.y - sin(angle) * tail)
                var streak = Path()
                streak.move(to: origin)
                streak.addLine(to: tip)
                context.stroke(
                    streak, with: .linearGradient(Gradient(colors: [.clear, tint.opacity(alpha)]),
                                                 startPoint: origin, endPoint: tip), lineWidth: 1 + strength
                )

                if index.isMultiple(of: 7) {
                    let crossRadius = 2 + 4 * strength
                    let spark = Path { path in
                        path.move(to: CGPoint(x: tip.x - crossRadius, y: tip.y))
                        path.addLine(to: CGPoint(x: tip.x + crossRadius, y: tip.y))
                        path.move(to: CGPoint(x: tip.x, y: tip.y - crossRadius))
                        path.addLine(to: CGPoint(x: tip.x, y: tip.y + crossRadius))
                    }
                    context.stroke(spark, with: .color(tint.opacity(alpha)), lineWidth: 1)
                }
            }
        }
    }
}
