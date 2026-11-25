import SwiftUI

enum LottoStyle {
    static let paper = Color(red: 0.973, green: 0.963, blue: 0.928)
    static let ink = Color(red: 0.105, green: 0.095, blue: 0.176)
    static let muted = Color(red: 0.34, green: 0.32, blue: 0.42)
    static let night = Color(red: 0.14, green: 0.09, blue: 0.30)
    static let lime = Color(red: 0.86, green: 0.96, blue: 0.44)
    static let violet = Color(red: 0.31, green: 0.23, blue: 0.66)
    static let line = ink.opacity(0.09)
}

struct NumberBall: View {
    let number: Int
    var marked = false
    var stage = false
    var muted = false

    private var color: Color {
        if marked { return LottoStyle.lime }
        guard stage else { return Color(red: 0.93, green: 0.91, blue: 0.99) }
        switch number {
        case 1...10: return LottoStyle.lime
        case 11...20: return Color(red: 0.83, green: 0.74, blue: 1)
        case 21...30: return Color(red: 1, green: 0.80, blue: 0.68)
        case 31...40: return Color(red: 0.69, green: 0.88, blue: 1)
        default: return Color(red: 1, green: 0.73, blue: 0.85)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle().fill(RadialGradient(colors: [.white, color, color.opacity(0.73)],
                                             center: .topLeading, startRadius: 1, endRadius: size))
                Circle().strokeBorder(marked ? LottoStyle.violet : .white.opacity(0.75),
                                      lineWidth: marked ? 2 : 1)
                Text(String(format: "%02d", number))
                    .font(.system(size: size * 0.43, weight: .black, design: .rounded))
                    .foregroundStyle(LottoStyle.ink)
                    .contentTransition(.identity)
                if marked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.16, weight: .black))
                        .foregroundStyle(LottoStyle.violet)
                        .offset(x: size * 0.29, y: size * 0.28)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(muted ? 0.53 : 1)
        .accessibilityLabel(marked ? "\(number)번 일치" : "\(number)번")
    }
}

struct BallRow: View {
    let numbers: [Int]
    var hits: Set<Int> = []
    var stage = false

    var body: some View {
        HStack(spacing: 7) {
            ForEach(numbers, id: \.self) { number in
                NumberBall(number: number, marked: hits.contains(number), stage: stage,
                           muted: !hits.isEmpty && !hits.contains(number))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct PrimaryLottoButton: View {
    let label: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .font(.headline.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 57)
                .foregroundStyle(LottoStyle.ink)
                .background(LottoStyle.lime, in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(LottoStyle.ink.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

struct LottoHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(.largeTitle, design: .rounded, weight: .black))
            Text(subtitle).font(.subheadline.weight(.medium)).foregroundStyle(LottoStyle.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func lottoCard() -> some View {
        self.padding(17)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(LottoStyle.line))
    }
}
