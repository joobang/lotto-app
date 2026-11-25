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
    static let firstCard = 0.08
    static let cardInterval = 0.057
    static let finale = 0.47
    static let duration = 1.43

    let reveal: DrawReveal

    var body: some View {
        TimelineView(.animation) { time in
            let elapsed = max(0, time.date.timeIntervalSince(reveal.start))
            GeometryReader { screen in
                let width = min(screen.size.width - 40, screen.size.height * 0.56, 440)
                let cell = (width - 18) / 3
                let height = cell * 1.19
                let centerY = screen.size.height * 0.51
                let exit = progress(elapsed, from: 1.17, over: Self.duration - 1.17)
                ZStack {
                    RewardBackdrop(elapsed: elapsed)
                    RewardPrism(elapsed: elapsed, size: min(width * 0.52, 192))
                        .position(x: screen.size.width / 2, y: centerY - 22)
                    VStack(spacing: 16) {
                        title(elapsed: elapsed)
                        VStack(spacing: 9) {
                            ForEach(0..<2, id: \.self) { row in
                                HStack(spacing: 9) {
                                    ForEach(0..<3, id: \.self) { column in
                                        let index = row * 3 + column
                                        rewardCell(index: index, elapsed: elapsed, width: cell, height: height)
                                    }
                                }
                            }
                        }
                        .frame(width: width)
                        progressTrack(elapsed: elapsed)
                    }
                    .frame(width: width)
                    .position(x: screen.size.width / 2, y: centerY)
                }
                .opacity(1 - exit * exit)
            }
        }
        .ignoresSafeArea()
    }

    private func title(elapsed: Double) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 9) {
                Capsule().fill(RewardPalette.gold.opacity(0.58)).frame(width: 24, height: 1)
                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RewardPalette.gold)
                Capsule().fill(RewardPalette.gold.opacity(0.58)).frame(width: 24, height: 1)
            }
            Text(reveal.title)
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: RewardPalette.iris, radius: 14)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .opacity(progress(elapsed, from: 0.06, over: 0.14))
    }

    private func rewardCell(index: Int, elapsed: Double, width: CGFloat, height: CGFloat) -> some View {
        let age = elapsed - Self.firstCard - Double(index) * Self.cardInterval
        let entry = progress(age, from: 0, over: 0.105)
        let travel = pow(1 - entry, 3)
        let impact = sin(.pi * progress(age, from: 0.025, over: 0.21))
        let tint = RewardPalette.cards[index]
        let direction = Double(index % 3 - 1)

        return ZStack {
            CutCorner().fill(RewardPalette.base.opacity(0.48))
                .overlay(CutCorner().strokeBorder(.white.opacity(0.20), lineWidth: 1))
                .overlay(Image(systemName: "diamond").foregroundStyle(.white.opacity(0.24)))
                .opacity(progress(elapsed, from: 0.045, over: 0.07) * (1 - entry))

            if age >= 0 {
                RewardCard(number: reveal.numbers[index], tint: tint, age: age, width: width)
                    .frame(width: width, height: height)
                    .scaleEffect(1 - 0.45 * travel + 0.10 * impact)
                    .rotation3DEffect(.degrees(72 * travel), axis: (x: 1, y: -direction * 0.65, z: 0), perspective: 0.50)
                    .offset(x: -direction * width * 0.66 * travel,
                            y: height * (index < 3 ? 0.6 : -0.6) * travel)
                    .opacity(min(1, entry * 3))
            }
        }
        .frame(width: width, height: height)
        .overlay {
            if age > 0.075 && age < 0.32 {
                CardBurst(age: age - 0.075, tint: tint)
                    .frame(width: width * 1.65, height: height * 1.48)
            }
        }
    }

    private func progressTrack(elapsed: Double) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<6) { index in
                let landed = elapsed >= Self.firstCard + Double(index) * Self.cardInterval
                Capsule().fill(landed ? RewardPalette.gold : .white.opacity(0.18))
                    .frame(width: 17, height: 3)
                    .shadow(color: landed ? RewardPalette.gold.opacity(0.7) : .clear, radius: 4)
            }
        }
        .opacity(progress(elapsed, from: 0.08, over: 0.12))
    }
}

private func progress(_ value: Double, from start: Double, over duration: Double) -> Double {
    min(1, max(0, (value - start) / duration))
}

private enum RewardPalette {
    static let base = Color(red: 0.035, green: 0.035, blue: 0.13)
    static let gold = Color(red: 1, green: 0.82, blue: 0.48)
    static let iris = Color(red: 0.59, green: 0.33, blue: 1)
    static let ice = Color(red: 0.29, green: 0.93, blue: 1)
    static let pink = Color(red: 1, green: 0.39, blue: 0.78)
    static let cards = [ice, iris, pink, Color(red: 0.38, green: 1, blue: 0.78),
                        Color(red: 0.42, green: 0.66, blue: 1), gold]
}

private struct CutCorner: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let c = min(bounds.width, bounds.height) * 0.13
        return Path { path in
            path.move(to: CGPoint(x: bounds.minX + c, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX - c, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY + c))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - c))
            path.addLine(to: CGPoint(x: bounds.maxX - c, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX + c, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY - c))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + c))
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> CutCorner {
        CutCorner(insetAmount: insetAmount + amount)
    }
}

private struct RewardCard: View {
    let number: Int
    let tint: Color
    let age: Double
    let width: CGFloat

    var body: some View {
        let flare = 1 - progress(age, from: 0.07, over: 0.26)
        let sweep = progress(age, from: 0.04, over: 0.43)
        ZStack {
            CutCorner()
                .fill(LinearGradient(colors: [tint.opacity(0.74), RewardPalette.base,
                                               tint.opacity(0.64), RewardPalette.base],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            DiamondShape()
                .strokeBorder(tint.opacity(0.65), lineWidth: 1)
                .frame(width: width * 0.72, height: width * 0.93)
                .background {
                    DiamondShape().fill(
                        LinearGradient(colors: [tint.opacity(0.23), RewardPalette.base.opacity(0.84), tint.opacity(0.46)],
                                       startPoint: .top, endPoint: .bottom))
                }
            Color.clear.overlay {
                Capsule()
                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.77), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: width * 0.38, height: width * 1.95)
                    .rotationEffect(.degrees(33))
                    .offset(x: width * (sweep * 2.0 - 1))
                    .blendMode(.plusLighter)
                    .opacity(sweep < 1 ? 0.96 : 0)
            }
            VStack {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                Spacer()
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.vertical, 9)
            .foregroundStyle(RewardPalette.gold)
            Text(number.formatted(.number.precision(.integerLength(2))))
                .font(.system(size: width * 0.47, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: RewardPalette.base, radius: 3, y: 2)
        }
        .clipShape(CutCorner())
        .overlay {
            CutCorner().strokeBorder(
                LinearGradient(colors: [.white, tint, RewardPalette.gold, tint.opacity(0.6)],
                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.4)
        }
        .overlay {
            CutCorner().inset(by: 5).strokeBorder(.white.opacity(0.42), lineWidth: 0.65)
        }
        .shadow(color: tint.opacity(0.60 + flare * 0.35), radius: 6 + 12 * flare)
    }
}

private struct DiamondShape: InsettableShape {
    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path { path in
            path.move(to: CGPoint(x: bounds.midX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.midY))
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> DiamondShape {
        DiamondShape(insetAmount: insetAmount + amount)
    }
}

private struct RewardPrism: View {
    let elapsed: Double
    let size: CGFloat

    var body: some View {
        let opening = progress(elapsed, from: 0, over: 0.22)
        let split = progress(elapsed, from: 0.065, over: 0.23)
        ZStack {
            DiamondShape()
                .strokeBorder(.white.opacity(0.66), lineWidth: 1)
                .frame(width: size * 0.73, height: size)
                .rotationEffect(.degrees(35 * opening))
            DiamondShape()
                .fill(AngularGradient(colors: [RewardPalette.ice, .white, RewardPalette.pink,
                                               RewardPalette.iris, RewardPalette.gold, RewardPalette.ice], center: .center))
                .frame(width: size * 0.46, height: size * 0.63)
                .overlay(Image(systemName: "sparkle").font(.system(size: size * 0.15)).foregroundStyle(.white))
                .rotation3DEffect(.degrees(120 * opening), axis: (x: 0.3, y: 1, z: 0.2))
        }
        .shadow(color: RewardPalette.ice, radius: size * 0.19)
        .scaleEffect(0.72 + 0.80 * opening)
        .opacity(1 - split)
    }
}

private struct CardBurst: View {
    let age: Double
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let phase = progress(age, from: 0, over: 0.245)
            let eased = 1 - pow(1 - phase, 2)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for index in 0..<14 {
                let angle = Double(index) * 2.39996
                let radius = size.width * (0.22 + 0.22 * eased)
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                let edge = index.isMultiple(of: 4) ? 6.0 : 2.5
                let shard = CGRect(x: point.x, y: point.y, width: edge, height: edge)
                context.fill(DiamondShape().path(in: shard), with: .color(
                    (index.isMultiple(of: 3) ? RewardPalette.gold : tint).opacity(1 - phase)))
            }
        }
    }
}

private struct RewardBackdrop: View {
    let elapsed: Double

    var body: some View {
        ZStack {
            RewardPalette.base
            RadialGradient(colors: [RewardPalette.iris.opacity(0.79), Color(red: 0.14, green: 0.11, blue: 0.37), .clear],
                           center: .center, startRadius: 30, endRadius: 375)
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.52)
                let width = size.width
                let burst = progress(elapsed, from: LottoCutscene.finale, over: 0.69)
                let launch = progress(elapsed, from: 0, over: 0.56)
                ribbons(context, width: width, center: center, burst: burst)
                debris(context, width: width, center: center, launch: launch, burst: burst)
            }
        }
    }

    private func ribbons(_ context: GraphicsContext, width: CGFloat, center: CGPoint, burst: Double) {
        for index in 0..<5 {
            var layer = context
            layer.translateBy(x: center.x, y: center.y)
            layer.rotate(by: .degrees(Double(index) * 37 + 66 * elapsed))
            let radius = width * (0.49 + Double(index) * 0.045 + burst * 0.25)
            let bounds = CGRect(x: -radius, y: -radius * 0.60, width: radius * 2, height: radius * 1.20)
            let path = Path(ellipseIn: bounds)
            let hot = RewardPalette.cards[index]
            let beam = Gradient(colors: [.clear, hot.opacity(0.77), .white.opacity(0.86), hot.opacity(0.28), .clear])
            let paint = GraphicsContext.Shading.linearGradient(beam, startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
                                                               endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY))
            var glow = layer
            glow.addFilter(.blur(radius: 10))
            glow.stroke(path, with: paint, lineWidth: 14)
            layer.stroke(path, with: paint, lineWidth: 1.8)
        }
        if burst > 0 && burst < 1 {
            let radius = width * (0.29 + burst * 0.90)
            let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            var glow = context
            glow.addFilter(.blur(radius: 9))
            let impact = RewardPalette.gold.opacity(1 - burst)
            glow.stroke(Path(ellipseIn: bounds), with: .color(impact), lineWidth: 23)
            context.stroke(Path(ellipseIn: bounds), with: .color(impact), lineWidth: 2.2)
        }
    }

    private func debris(_ context: GraphicsContext, width: CGFloat, center: CGPoint, launch: Double, burst: Double) {
        for index in 0..<92 {
            let angle = Double(index) * 2.39996 + 0.13 * elapsed
            let strength = Double((index * 41 + 12) % 97) / 97
            let outward = index.isMultiple(of: 2) ? launch : burst
            let distance = width * (0.27 + 0.86 * strength + outward * (0.39 + 0.49 * strength))
            let tail = 2 + strength * (6 + 24 * sin(.pi * outward))
            let tint = RewardPalette.cards[index % RewardPalette.cards.count]
            let tip = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            let origin = CGPoint(x: tip.x - cos(angle) * tail, y: tip.y - sin(angle) * tail)
            let alpha = (0.32 + strength * 0.63) * (1 - 0.54 * outward)
            var streak = Path()
            streak.move(to: origin)
            streak.addLine(to: tip)
            context.stroke(streak, with: .linearGradient(Gradient(colors: [.clear, tint.opacity(alpha)]),
                                                         startPoint: origin, endPoint: tip), lineWidth: 1 + 2 * strength)
            if index.isMultiple(of: 4) {
                let side = 3 + 5 * strength
                let bounds = CGRect(x: tip.x, y: tip.y, width: side, height: side * 1.5)
                context.fill(DiamondShape().path(in: bounds), with: .color(tint.opacity(alpha)))
            }
        }
    }
}
