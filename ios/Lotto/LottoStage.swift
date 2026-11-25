import SwiftUI

struct LaunchInput {
    let origin: CGPoint
    let diameter: CGFloat
    let charge: Double
}

struct DrawLauncher: View {
    let compact: Bool
    let identifier: String
    let onRelease: (LaunchInput) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var pull: CGFloat = 0

    private static let chamber = UIImage(named: "draw-launcher.jpg")
    private let ice = Color(red: 0.60, green: 0.88, blue: 1)
    private let amber = Color(red: 1, green: 0.81, blue: 0.52)
    private var threshold: CGFloat { compact ? 54 : 72 }
    private var travel: CGFloat { threshold + 17 }
    private var diameter: CGFloat { compact ? 61 : 84 }
    private var armed: Bool { pull >= threshold }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let frame = geometry.frame(in: .global)
            let center = CGPoint(x: size.width * 0.5, y: size.height * (compact ? 0.40 : 0.47))
            let charge = min(1, pull / threshold)

            ZStack {
                chamber(size: size, charge: charge)
                guide(center: center, charge: charge)
                orb(center: center, frame: frame, charge: charge)
                instruction
                    .position(x: center.x, y: size.height - (compact ? 25 : 31))
            }
            .clipShape(RoundedRectangle(cornerRadius: compact ? 19 : 30))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 19 : 30)
                    .strokeBorder((armed ? amber : .white).opacity(armed ? 0.75 : 0.29))
                    .allowsHitTesting(false)
            }
        }
        .frame(height: compact ? 252 : 365)
        .shadow(color: Color(red: 0.16, green: 0.10, blue: 0.32).opacity(compact ? 0.15 : 0.24), radius: 14, y: 7)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.80), trigger: armed) { _, ready in ready }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: pull == 0)
    }

    private func chamber(size: CGSize, charge: CGFloat) -> some View {
        ZStack {
            LottoStyle.night
            if let image = Self.chamber {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .brightness(Double(charge) * 0.11)
                    .scaleEffect(1 + charge * 0.035, anchor: .top)
            }
            LinearGradient(colors: [.clear, LottoStyle.night.opacity(0.10), .black.opacity(0.72)],
                           startPoint: .center, endPoint: .bottom)
        }
        .accessibilityHidden(true)
    }

    private func guide(center: CGPoint, charge: CGFloat) -> some View {
        let tone = armed ? amber : ice
        return Canvas { context, _ in
            let head = CGPoint(x: center.x, y: center.y - diameter * 0.92)
            let tail = CGPoint(x: center.x, y: center.y + travel)
            var rail = Path()
            rail.move(to: head)
            rail.addLine(to: tail)
            context.stroke(rail, with: .linearGradient(
                Gradient(colors: [.clear, tone.opacity(0.50), tone.opacity(0.72)]),
                startPoint: head, endPoint: tail), lineWidth: 1 + charge * 2)

            let destination = CGPoint(x: center.x, y: center.y + threshold)
            for side in [-1.0, 1.0] {
                let edge = center.x + side * (diameter * 0.53 + 9)
                for index in 0..<5 {
                    let y = center.y + Double(index) * threshold / 4
                    let length = index == 4 ? 11.0 : 5.0
                    let active = Double(charge) >= Double(index) / 4
                    var tick = Path()
                    tick.move(to: CGPoint(x: edge, y: y))
                    tick.addLine(to: CGPoint(x: edge + side * length, y: y))
                    context.stroke(tick, with: .color(tone.opacity(active ? 0.90 : 0.24)), lineWidth: 1.5)
                }
            }

            let lock = CGRect(x: destination.x - diameter * 0.59, y: destination.y - diameter * 0.59,
                              width: diameter * 1.18, height: diameter * 1.18)
            context.stroke(Path(ellipseIn: lock), with: .color(tone.opacity(0.29 + 0.38 * charge)),
                           style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func orb(center: CGPoint, frame: CGRect, charge: CGFloat) -> some View {
        let drag = DragGesture(minimumDistance: 3, coordinateSpace: .global)
            .updating($pull) { value, state, transaction in
                transaction.animation = nil
                state = min(travel, max(0, value.translation.height))
            }
            .onEnded { value in
                guard value.translation.height >= threshold else { return }
                let distance = min(travel, value.translation.height)
                onRelease(LaunchInput(origin: CGPoint(x: frame.minX + center.x, y: frame.minY + center.y + distance),
                                      diameter: diameter, charge: min(1, distance / travel)))
            }

        return LaunchSphere(diameter: diameter, charge: charge, armed: armed)
            .overlay {
                Image(systemName: "arrow.down")
                    .font(.system(size: diameter * 0.29, weight: .semibold))
                    .foregroundStyle(Color(red: 0.17, green: 0.10, blue: 0.37))
                    .opacity(1 - charge)
                    .allowsHitTesting(false)
            }
            .contentShape(Circle())
            .highPriorityGesture(drag)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("발사 공")
            .accessibilityHint("아래로 당겨 놓거나 이 항목을 활성화해서 뽑습니다")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(identifier)
            .accessibilityAction {
                onRelease(LaunchInput(origin: CGPoint(x: frame.minX + center.x, y: frame.minY + center.y),
                                      diameter: diameter, charge: 0.8))
            }
            .position(x: center.x, y: center.y + pull)
    }

    private var instruction: some View {
        Label(armed ? "놓으면 발사돼요" : "공을 아래로 당겨 놓기",
              systemImage: armed ? "sparkle" : "chevron.down")
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(armed ? amber : .white)
            .padding(.horizontal, 13).padding(.vertical, 7)
            .background(.black.opacity(0.58), in: Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsHitTesting(false)
    }
}

private struct LaunchSphere: View {
    let diameter: CGFloat
    let charge: CGFloat
    let armed: Bool

    var body: some View {
        let glow = armed ? Color(red: 1, green: 0.76, blue: 0.41) : Color(red: 0.64, green: 0.54, blue: 1)
        return ZStack {
            Circle().fill(RadialGradient(colors: [.white, Color(red: 0.87, green: 0.93, blue: 1), glow,
                                                   Color(red: 0.22, green: 0.11, blue: 0.48)],
                                          center: .init(x: 0.32, y: 0.25), startRadius: 0, endRadius: diameter * 0.89))
            Circle().fill(RadialGradient(colors: [.white.opacity(0.78), .clear], center: .init(x: 0.72, y: 0.82),
                                         startRadius: 0, endRadius: diameter * 0.43))
            Circle().strokeBorder(.white.opacity(0.86), lineWidth: 1.3)
            Ellipse().fill(.white.opacity(0.83))
                .frame(width: diameter * 0.34, height: diameter * 0.092)
                .blur(radius: 2.1).rotationEffect(.degrees(-26))
                .offset(x: -diameter * 0.19, y: -diameter * 0.29)
        }
        .frame(width: diameter, height: diameter)
        .overlay {
            Circle().trim(from: 0, to: charge).stroke(glow, style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(-6)
        }
        .shadow(color: glow.opacity(0.77), radius: 8 + charge * 12)
    }
}

struct DrawReveal: Identifiable {
    let id = UUID()
    let start = Date()
    let numbers: [Int]
    let title: String
    let launch: LaunchInput?
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

                let frame = bounds.frame(in: .global)
                let origin = reveal.launch.map { CGPoint(x: $0.origin.x - frame.minX, y: $0.origin.y - frame.minY) }
                    ?? CGPoint(x: size.width / 2, y: size.height * 0.70)

                ZStack {
                    environment(size: size, elapsed: elapsed)
                        .opacity(ramp(elapsed, start: 0, length: 0.12))
                    optics(gate: gate, elapsed: elapsed)
                    if elapsed < 0.29 {
                        projectile(from: origin, to: gate, elapsed: elapsed, width: size.width)
                    }
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

    private func projectile(from origin: CGPoint, to gate: CGPoint, elapsed: Double, width: CGFloat) -> some View {
        let phase = ramp(elapsed, start: 0, length: 0.29)
        let travel = 0.45 * phase + 0.55 * pow(phase, 2)
        let bend = CGPoint(x: gate.x - width * 0.30, y: gate.y + (origin.y - gate.y) * 0.42)
        let middle = interpolate(interpolate(origin, bend, travel), interpolate(bend, gate, travel), travel)
        let size = (reveal.launch?.diameter ?? 84) * (1 - travel * 0.78)
        let charge = reveal.launch?.charge ?? 0.8
        return ZStack {
            LaunchTrail(from: origin, to: middle, color: Self.ice)
                .opacity(ramp(elapsed, start: 0.024, length: 0.15) * (1 - phase * 0.32))
            LaunchSphere(diameter: size, charge: charge * (1 - phase), armed: true)
                .position(middle)
        }
    }

    private func optics(gate: CGPoint, elapsed: Double) -> some View {
        Canvas { context, size in
            gateFlare(context, gate: gate, size: size, age: elapsed - 0.26)
            shockwave(context, center: gate, width: size.width,
                      phase: ramp(elapsed, start: 0.27, length: 0.45), tint: Self.ice)
            shockwave(context, center: gate, width: size.width,
                      phase: ramp(elapsed, start: Self.lastImpact, length: 0.60), tint: Self.gold)
        }
    }

    private func gateFlare(_ context: GraphicsContext, gate: CGPoint, size: CGSize, age: Double) {
        guard age > 0, age < 0.24 else { return }
        let bloom = min(1, age / 0.044) * pow(1 - age / 0.24, 2)
        let spread = size.width * (0.26 + age * 1.6)
        let halo = CGRect(x: gate.x - spread, y: gate.y - spread,
                          width: spread * 2, height: spread * 2)
        context.fill(Path(ellipseIn: halo), with: .radialGradient(
            Gradient(colors: [.white.opacity(bloom * 0.94), Self.ice.opacity(bloom * 0.40), .clear]),
            center: gate, startRadius: 0, endRadius: spread))

        for index in 0..<3 {
            var streak = context
            streak.translateBy(x: gate.x, y: gate.y)
            streak.rotate(by: .degrees(Double(index - 1) * 13))
            let beam = CGRect(x: -size.width * 0.58, y: -2.5, width: size.width * 1.16, height: 5)
            let tint = index == 1 ? Self.ice : Self.gold
            streak.fill(Path(ellipseIn: beam), with: .linearGradient(
                Gradient(colors: [.clear, tint.opacity(bloom), .white.opacity(bloom), tint.opacity(bloom), .clear]),
                startPoint: CGPoint(x: beam.minX, y: 0), endPoint: CGPoint(x: beam.maxX, y: 0)))
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
