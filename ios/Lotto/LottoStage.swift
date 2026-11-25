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
    static let firstBall = 0.31
    static let ballInterval = 0.058
    static let duration = 1.62
    private static let lastImpact = 0.70
    private static let abyss = Color(red: 0.023, green: 0.026, blue: 0.105)
    private static let ice = Color(red: 0.37, green: 0.91, blue: 1)
    private static let gold = Color(red: 1, green: 0.81, blue: 0.49)
    private static let vortex = UIImage(named: "draw-vortex.jpg")

    let reveal: DrawReveal

    var body: some View {
        TimelineView(.animation) { time in
            let elapsed = max(0, time.date.timeIntervalSince(reveal.start))
            GeometryReader { bounds in
                let size = bounds.size
                let diameter = min(size.width * 0.255, size.height * 0.20, 124)
                let gate = CGPoint(x: size.width * 0.50, y: size.height * 0.425)
                let center = CGPoint(x: gate.x, y: size.height * 0.56)
                let fade = ramp(elapsed, start: 1.33, length: Self.duration - 1.33)

                ZStack {
                    environment(size: size, elapsed: elapsed)
                    optics(gate: gate, elapsed: elapsed)
                    heading(elapsed: elapsed)
                        .position(x: center.x, y: center.y - diameter * 1.56)
                    ForEach(Array(reveal.numbers.enumerated()), id: \.offset) { index, number in
                        let anchor = slot(index: index, center: center, diameter: diameter)
                        flyingNumber(number, index: index, elapsed: elapsed,
                                     from: gate, to: anchor, diameter: diameter)
                    }
                }
                .opacity(1 - fade * fade)
            }
        }
        .ignoresSafeArea()
    }

    private func environment(size: CGSize, elapsed: Double) -> some View {
        let dive = eased(ramp(elapsed, start: 0, length: 0.32))
        let settle = ramp(elapsed, start: 0.28, length: 0.42)
        return ZStack {
            Self.abyss
            if let vortex = Self.vortex {
                Image(uiImage: vortex)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .rotationEffect(.degrees(-11 * (1 - dive) + 4 * settle))
                    .scaleEffect(1.06 + 0.44 * (1 - dive) + 0.08 * settle)
                    .brightness(-0.20 * (1 - dive) - 0.08 * settle)
            }
            LinearGradient(colors: [Self.abyss.opacity(0.53), .clear, .clear, Self.abyss.opacity(0.61)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Self.abyss.opacity(0.61), Self.abyss.opacity(0.21), .clear],
                           center: UnitPoint(x: 0.50, y: 0.55), startRadius: size.width * 0.06, endRadius: size.width * 0.53)
                .opacity(settle)
        }
        .clipped()
    }

    private func heading(elapsed: Double) -> some View {
        let legibility = ramp(elapsed, start: 0.46, length: 0.23)
        return Text(reveal.title)
            .font(.system(.title2, design: .rounded, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Self.abyss.opacity(0.58), in: Capsule())
            .shadow(color: .black.opacity(0.45), radius: 6, y: 2)
            .opacity(legibility)
    }

    private func slot(index: Int, center: CGPoint, diameter: CGFloat) -> CGPoint {
        let lane = Double(index % 3 - 1)
        let row = index < 3 ? -0.62 : 0.67
        return CGPoint(x: center.x + lane * diameter * 1.19,
                       y: center.y + (row + abs(lane) * (index < 3 ? 0.10 : -0.06)) * diameter)
    }

    private func flyingNumber(_ number: Int, index: Int, elapsed: Double, from gate: CGPoint,
                              to anchor: CGPoint, diameter: CGFloat) -> some View {
        let age = elapsed - Self.firstBall - Self.ballInterval * Double(index)
        let entry = ramp(age, start: 0, length: 0.115)
        let travel = eased(entry)
        let pitch = sin(entry * .pi) * diameter * (index < 3 ? -0.47 : 0.41)
        let impact = sin(.pi * ramp(age, start: 0.06, length: 0.24))
        let tint = LottoStyle.drawBallTint(number)
        let origin = interpolate(gate, anchor, travel)
        let position = CGPoint(x: origin.x, y: origin.y + pitch)

        return ZStack {
            if age >= 0 {
                if entry < 1 {
                    LaunchTrail(from: gate, to: position, color: tint)
                        .opacity(0.9 * (1 - entry))
                }
                if age >= 0.09 && age < 0.39 {
                    SparkSpray(color: tint, phase: ramp(age, start: 0.09, length: 0.30))
                        .frame(width: diameter * 2, height: diameter * 2)
                        .position(anchor)
                }
                RevealSphere(number: number, tint: tint, diameter: diameter, impact: impact)
                    .rotationEffect(.degrees((index.isMultiple(of: 2) ? 50 : -50) * (1 - travel)))
                    .scaleEffect(0.27 + travel * 0.73 + 0.095 * impact)
                    .opacity(min(1, entry * 3))
                    .position(position)
            }
        }
    }

    private func optics(gate: CGPoint, elapsed: Double) -> some View {
        Canvas { context, size in
            if elapsed < 0.30 {
                let speed = ramp(elapsed, start: 0, length: 0.30)
                let start = CGPoint(x: size.width * 0.93, y: size.height * 0.13)
                let bend = CGPoint(x: size.width * 0.06, y: size.height * 0.19)
                func trajectory(_ t: Double) -> CGPoint {
                    let step = t * t
                    return interpolate(interpolate(start, bend, step), interpolate(bend, gate, step), step)
                }
                for index in 0..<29 {
                    let end = speed - Double(index) * 0.011
                    guard end > 0 else { break }
                    var shard = Path()
                    shard.move(to: trajectory(max(0, end - 0.026)))
                    shard.addLine(to: trajectory(end))
                    let trail = 1 - Double(index) / 29
                    context.stroke(shard, with: .color(Self.ice.opacity(trail * 0.48)), lineWidth: 4 + 15 * trail)
                    context.stroke(shard, with: .color(.white.opacity(trail)), lineWidth: 5 * trail)
                }
                let head = trajectory(speed)
                let core = CGRect(x: head.x - 5, y: head.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: core), with: .color(.white))
            }
            shockwave(context, center: gate, width: size.width,
                      phase: ramp(elapsed, start: 0.27, length: 0.45), tint: Self.ice)
            shockwave(context, center: gate, width: size.width,
                      phase: ramp(elapsed, start: Self.lastImpact, length: 0.60), tint: Self.gold)
        }
    }

    private func shockwave(_ context: GraphicsContext, center: CGPoint, width: CGFloat,
                           phase: Double, tint: Color) {
        guard phase > 0, phase < 1 else { return }
        let reach = eased(phase)
        let radius = width * (0.06 + reach * 0.95)
        let oval = CGRect(x: center.x - radius, y: center.y - radius * 0.81,
                          width: radius * 2, height: radius * 1.62)
        let alpha = pow(1 - phase, 1.5)
        let front = Path(ellipseIn: oval)
        var bloom = context
        bloom.addFilter(.blur(radius: 9))
        bloom.stroke(front, with: .color(tint.opacity(alpha)), lineWidth: 22)
        context.stroke(front, with: .color(tint.opacity(alpha)), lineWidth: 2.4)
        for index in 0..<48 {
            let angle = Double(index) * 2.39996
            let variation = Double((index * 19 + 11) % 37) / 37
            let distance = width * (0.07 + reach * (0.32 + variation * 0.84))
            let trailLength = 3 + 25 * variation * alpha
            let dx = cos(angle)
            let dy = sin(angle)
            let head = CGPoint(x: center.x + dx * distance, y: center.y + dy * distance)
            let tail = CGPoint(x: head.x - dx * trailLength, y: head.y - dy * trailLength)
            var path = Path()
            path.move(to: tail)
            path.addLine(to: head)
            context.stroke(path, with: .linearGradient(Gradient(colors: [.clear, tint.opacity(alpha)]),
                                                       startPoint: tail, endPoint: head), lineWidth: 1 + variation * 2.2)
        }
    }
}

private func ramp(_ value: Double, start: Double, length: Double) -> Double {
    min(1, max(0, (value - start) / length))
}

private func eased(_ fraction: Double) -> Double { 1 - pow(1 - fraction, 3) }

private func interpolate(_ a: CGPoint, _ b: CGPoint, _ fraction: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
}

private struct RevealSphere: View {
    let number: Int
    let tint: Color
    let diameter: CGFloat
    let impact: Double

    var body: some View {
        let shade = Color(red: 0.06, green: 0.06, blue: 0.17)
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white, tint.opacity(0.97), tint, shade],
                                     center: UnitPoint(x: 0.28, y: 0.21), startRadius: 1, endRadius: diameter * 0.93))
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.73), tint.opacity(0.13), .clear],
                                     center: UnitPoint(x: 0.75, y: 0.81), startRadius: 0, endRadius: diameter * 0.42))
            Circle().strokeBorder(LinearGradient(colors: [.white, .white.opacity(0.1), tint, .white.opacity(0.81)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            Ellipse().fill(.white.opacity(0.81))
                .frame(width: diameter * 0.32, height: diameter * 0.085)
                .blur(radius: diameter * 0.025)
                .rotationEffect(.degrees(-26))
                .offset(x: -diameter * 0.19, y: -diameter * 0.31)
            Circle()
                .fill(LinearGradient(colors: [.white, Color(red: 0.95, green: 0.96, blue: 1), tint.opacity(0.94)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Circle().strokeBorder(.white.opacity(0.76), lineWidth: 1.4))
                .frame(width: diameter * 0.62)
                .shadow(color: shade.opacity(0.57), radius: 3, y: 2)
                .overlay {
                    Text(number.formatted(.number.precision(.integerLength(2))))
                        .font(.system(size: diameter * 0.34, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(LottoStyle.ink)
                }
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: tint.opacity(0.75), radius: 6 + 13 * impact)
        .shadow(color: shade.opacity(0.64), radius: 6, y: 5)
    }
}

private struct LaunchTrail: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color

    var body: some View {
        Canvas { context, _ in
            var path = Path()
            path.move(to: from)
            let bend = CGPoint(x: (from.x + to.x) / 2, y: min(from.y, to.y) - 35)
            path.addQuadCurve(to: to, control: bend)
            let light = Gradient(colors: [.clear, color.opacity(0.30), color, .white])
            let paint = GraphicsContext.Shading.linearGradient(light, startPoint: from, endPoint: to)
            context.stroke(path, with: paint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
            context.stroke(path, with: .color(.white.opacity(0.72)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

private struct SparkSpray: View {
    let color: Color
    let phase: Double

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            for index in 0..<16 {
                let angle = Double(index) * 2.39996
                let distance = size.width * (0.21 + eased(phase) * (0.11 + Double(index % 5) * 0.023))
                let tip = CGPoint(x: origin.x + cos(angle) * distance, y: origin.y + sin(angle) * distance)
                let side = index.isMultiple(of: 3) ? 5.0 : 2.7
                let diamond = Path { path in
                    path.move(to: CGPoint(x: tip.x, y: tip.y - side))
                    path.addLine(to: CGPoint(x: tip.x + side * 0.50, y: tip.y))
                    path.addLine(to: CGPoint(x: tip.x, y: tip.y + side))
                    path.addLine(to: CGPoint(x: tip.x - side * 0.50, y: tip.y))
                    path.closeSubpath()
                }
                context.fill(diamond, with: .color((index.isMultiple(of: 3) ? .white : color).opacity(1 - phase)))
            }
        }
    }
}
