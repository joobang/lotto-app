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
                chamber(charge: charge)
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

    private func chamber(charge: CGFloat) -> some View {
        ZStack {
            CinemaSurface(mode: .chamber(charge))
            LinearGradient(colors: [.clear, .clear, Color(red: 0.025, green: 0.044, blue: 0.10).opacity(0.91)],
                           startPoint: .top, endPoint: .bottom)
        }
        .allowsHitTesting(false)
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
        let glow = armed ? Color(red: 1, green: 0.76, blue: 0.41) : Color(red: 0.36, green: 0.64, blue: 1)
        return ZStack {
            Circle().fill(RadialGradient(colors: [.white, Color(red: 0.87, green: 0.93, blue: 1), glow,
                                                   Color(red: 0.054, green: 0.15, blue: 0.36)],
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
    static let collision = 0.27
    static let impactHold = 0.055
    static let firstBall = 0.36
    static let ballInterval = 0.088
    static let ballFlight = 0.29
    static let landingCue = 0.18
    static let duration = 1.94

    let reveal: DrawReveal

    var body: some View {
        GeometryReader { bounds in
            let origin = reveal.launch?.origin ?? CGPoint(x: bounds.size.width / 2, y: bounds.size.height * 0.68)
            let frame = bounds.frame(in: .global)
            let position = CGPoint(x: (origin.x - frame.minX) / bounds.size.width,
                                   y: (origin.y - frame.minY) / bounds.size.height)

            ZStack {
                CinemaSurface(mode: .reveal(reveal, position))
                    .ignoresSafeArea()
                LinearGradient(colors: [Color(red: 0.016, green: 0.029, blue: 0.071).opacity(0.91), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: bounds.size.height * 0.36)
                    .frame(maxHeight: .infinity, alignment: .top)
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(reveal.start)
                    let title = min(1, max(0, (elapsed - 0.86) / 0.20))
                    ZStack {
                        CollisionLight(age: elapsed - Self.collision)
                        VStack(spacing: 10) {
                            Rectangle().fill(LottoStyle.gold).frame(width: 26, height: 1)
                            Text(reveal.title)
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(.white)
                        }
                        .opacity(title)
                        .offset(y: 7 * (1 - title))
                        .position(x: bounds.size.width / 2, y: bounds.size.height * 0.23)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .modifier(RevealDissolve(start: reveal.start))
    }
}

private struct RevealDissolve: ViewModifier {
    let start: Date

    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            let exit = min(1, max(0, (elapsed - 1.64) / (LottoCutscene.duration - 1.64)))
            let enter = min(1, max(0, elapsed / 0.075))
            content.opacity(enter * (1 - exit * exit))
        }
    }
}

private struct CollisionLight: View {
    let age: Double

    var body: some View {
        GeometryReader { geometry in
            if age >= 0 && age < 0.28 {
                let exposure = exp(-age * 19)
                let radius = geometry.size.width * (0.23 + 0.40 * (1 - exp(-age * 10)))
                ZStack {
                    Circle().fill(RadialGradient(
                        colors: [.white.opacity(0.84), LottoStyle.gold.opacity(0.36), .clear],
                        center: .center, startRadius: 0, endRadius: radius
                    ))
                    .frame(width: radius * 2, height: radius * 2)
                    Ellipse().fill(LinearGradient(
                        colors: [.clear, LottoStyle.gold.opacity(0.64), .white, LottoStyle.gold.opacity(0.64), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * (0.78 + age), height: 5)
                    .rotationEffect(.degrees(-8))
                    .blur(radius: 1.1)
                }
                .opacity(exposure)
                .blendMode(.screen)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.45)
            }
        }
    }
}
