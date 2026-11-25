import SwiftUI

struct LottoStage: View {
    let numbers: [Int]
    let shine: Bool

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
                    .shadow(color: LottoStyle.lime.opacity(shine ? 0.53 : 0.13), radius: shine ? 14 : 5)
                    .accessibilityIdentifier("draw-result")
            }
        }
        .padding(23)
        .frame(minHeight: 354)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 30).fill(LottoStyle.night)
            RoundedRectangle(cornerRadius: 30).fill(
                RadialGradient(colors: [LottoStyle.violet.opacity(shine ? 1 : 0.72), .clear],
                               center: .bottomTrailing, startRadius: 4, endRadius: 320))
            GeometryReader { bounds in
                StageOrbits(shine: shine)
                StageOrb(shine: shine)
                    .frame(width: bounds.size.width * 0.46, height: bounds.size.width * 0.46)
                    .position(x: bounds.size.width * 0.72, y: bounds.size.height * 0.48)
            }.clipShape(RoundedRectangle(cornerRadius: 30))
        }
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.14)))
        .shadow(color: LottoStyle.night.opacity(0.18), radius: 19, y: 10)
    }
}

private struct StageOrbits: View {
    let shine: Bool

    var body: some View {
        Canvas { context, size in
            for index in 0..<8 {
                let offset = Double(index) * 13
                let rect = CGRect(x: size.width * 0.43 - offset, y: -130 + offset,
                                  width: size.width * 0.94 + offset, height: size.height + 138 - offset)
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(shine ? 0.28 : 0.10)), lineWidth: 1)
            }
            for index in 0..<31 {
                let x = Double((index * 71 + 18) % 337) / 337 * size.width
                let y = Double((index * 47 + 13) % 211) / 211 * size.height
                let diameter = index % 6 == 0 ? 3.4 : 1.6
                let dot = CGRect(x: x, y: y, width: diameter, height: diameter)
                context.fill(Path(ellipseIn: dot), with: .color(
                    (index % 6 == 0 ? LottoStyle.lime : .white).opacity(shine ? 0.78 : 0.34)))
            }
        }.accessibilityHidden(true)
    }
}

private struct StageOrb: View {
    let shine: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [
                    Color(red: 0.89, green: 0.84, blue: 1),
                    Color(red: 0.58, green: 0.47, blue: 0.94),
                    Color(red: 0.34, green: 0.22, blue: 0.68),
                    Color(red: 0.15, green: 0.10, blue: 0.38)
                ], center: .topLeading, startRadius: 6, endRadius: 164))
                .shadow(color: .purple.opacity(shine ? 0.85 : 0.42), radius: 25)
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
        .scaleEffect(shine ? 1.05 : 1)
        .accessibilityHidden(true)
    }
}
