import SwiftUI

struct CountRow: View {
    let number: Int
    let count: Int
    let maximum: Int

    var body: some View {
        HStack(spacing: 12) {
            NumberBall(number: number).frame(width: 32, height: 32)
            GeometryReader { proxy in
                Capsule().fill(LottoStyle.line)
                    .overlay(alignment: .leading) {
                        Capsule().fill(LottoStyle.violet)
                            .frame(width: proxy.size.width * CGFloat(count) / CGFloat(max(1, maximum)))
                    }
            }.frame(height: 7).accessibilityHidden(true)
            Text("\(count)회").font(.subheadline.monospacedDigit().weight(.bold))
                .frame(minWidth: 50, alignment: .trailing)
        }.accessibilityElement(children: .combine)
    }
}

struct AnalysisView: View {
    private enum Page: String, CaseIterable {
        case summary = "요약"
        case rounds = "닮은 회차"
        case numbers = "번호별"
        case pairs = "번호 쌍"
    }

    let line: SavedLine
    let history: LottoHistory
    private let analysis: DrawAnalysis
    @Environment(\.dismiss) private var dismiss
    @State private var page = Page.summary

    init(line: SavedLine, history: LottoHistory) {
        self.line = line
        self.history = history
        self.analysis = history.analyze(line.numbers)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView(selection: $page) {
                sheetPage(summary).tag(Page.summary)
                sheetPage(rounds).tag(Page.rounds)
                sheetPage(numbers).tag(Page.numbers)
                sheetPage(pairs).tag(Page.pairs)
            }.tabViewStyle(.page(indexDisplayMode: .never))
        }
        .foregroundStyle(LottoStyle.ink)
        .background(LottoStyle.paper.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 13) {
            HStack(alignment: .top) {
                LottoHeading(title: line.name, subtitle: history.range)
                Button("닫기", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.bold)).frame(width: 44, height: 44)
                    .background(.white, in: Circle())
            }
            BallRow(numbers: line.numbers)
            HStack(spacing: 4) {
                ForEach(Page.allCases, id: \.self) { item in
                    Button(item.rawValue) {
                        withAnimation(.easeInOut(duration: 0.2)) { page = item }
                    }
                    .font(.footnote.weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(page == item ? .white : LottoStyle.ink)
                    .background(page == item ? LottoStyle.night : .white, in: Capsule())
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(page == item ? .isSelected : [])
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 10)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var summary: some View {
        if let closest = analysis.matches.first {
            VStack(alignment: .leading, spacing: 12) {
                Text("역대 최고 일치").font(.subheadline.weight(.bold)).foregroundStyle(LottoStyle.lime)
                Text("\(analysis.best)개가 함께\n나온 적이 있어요")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                Text("전체에서 \(analysis.bestCount)회 · 가장 최근 \(closest.id)회")
                    .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.86))
                BallRow(numbers: line.numbers, hits: closest.hits, stage: true)
                Button("닮은 회차 더 보기", systemImage: "arrow.up.right") { page = .rounds }
                    .font(.subheadline.weight(.bold)).foregroundStyle(LottoStyle.lime)
                    .padding(.top, 3)
            }
            .padding(18)
            .background(
                LinearGradient(colors: [LottoStyle.night, LottoStyle.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24)
            )
            VStack(alignment: .leading, spacing: 12) {
                Text("3개 이상 일치한 회차").font(.headline)
                HStack(spacing: 6) {
                    ForEach(3...6, id: \.self) { hits in
                        VStack(spacing: 5) {
                            Text("\(hits)개").font(.caption.weight(.semibold)).foregroundStyle(LottoStyle.muted)
                            Text("\(analysis.distribution[hits])회").font(.subheadline.weight(.black))
                        }.frame(maxWidth: .infinity, minHeight: 63)
                            .background(LottoStyle.paper, in: RoundedRectangle(cornerRadius: 13))
                    }
                }
            }.lottoCard()
        } else {
            Text(history.draws.isEmpty ? "비교할 역대 이력을 불러오지 못했어요." : "일치하는 번호가 없어요.")
                .frame(maxWidth: .infinity, alignment: .leading).lottoCard()
        }
    }

    private var rounds: some View {
        Group {
            Text("일치한 번호가 많은 순으로 최대 10회").font(.subheadline).foregroundStyle(LottoStyle.muted)
            ForEach(analysis.matches) { match in
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("\(match.id)회").font(.title3.weight(.black))
                        Text(match.draw.drawDate).font(.caption).foregroundStyle(LottoStyle.muted)
                        Spacer()
                        Text("\(match.hits.count)개 일치")
                            .font(.caption.weight(.bold)).padding(8)
                            .background(LottoStyle.lime, in: Capsule())
                    }
                    Text("당첨번호").font(.caption.weight(.semibold)).foregroundStyle(LottoStyle.muted)
                    BallRow(numbers: match.draw.numbers, hits: match.hits)
                    Text("내 번호").font(.caption.weight(.semibold)).foregroundStyle(LottoStyle.muted)
                    BallRow(numbers: line.numbers, hits: match.hits)
                    Text("보너스 \(match.draw.bonus)번 · 일치 개수에서 제외")
                        .font(.caption).foregroundStyle(LottoStyle.muted)
                }.lottoCard()
            }
        }
    }

    private var numbers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내 번호가 나온 횟수").font(.headline)
            let maximum = history.ranking.first?.count ?? 1
            ForEach(line.numbers, id: \.self) { number in
                CountRow(number: number, count: history.counts[number, default: 0], maximum: maximum)
            }
        }.lottoCard()
    }

    private var pairs: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("같은 회차에 함께 나온 번호").font(.headline)
            ForEach(Array(analysis.pairs.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: 6) {
                    NumberBall(number: pair.first).frame(width: 34, height: 34)
                    NumberBall(number: pair.second).frame(width: 34, height: 34)
                    Spacer()
                    Text("\(pair.count)회").font(.subheadline.monospacedDigit().weight(.bold))
                }.accessibilityElement(children: .combine)
            }
        }.lottoCard()
    }

    private func sheetPage<Body: View>(_ body: Body) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 13) { body }
                .padding(.horizontal, 20).padding(.vertical, 8)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
    }
}

struct NumberEditor: View {
    let line: SavedLine
    let existing: [SavedLine]
    let onSave: (SavedLine) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selection: Set<Int>

    init(line: SavedLine, existing: [SavedLine], onSave: @escaping (SavedLine) -> Void) {
        self.line = line
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: line.name)
        _selection = State(initialValue: Set(line.numbers))
    }

    private var duplicate: Bool {
        existing.contains { $0.id != line.id && $0.numbers == selection.sorted() }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    LottoHeading(title: line.numbers.isEmpty ? "번호 직접 추가" : "조합 수정",
                                 subtitle: "\(selection.count) / 6 선택")
                    Button("닫기", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly).frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                }
                TextField("조합 이름", text: $name).textFieldStyle(.plain).lottoCard()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 5) {
                    ForEach(1...45, id: \.self) { number in
                        Button {
                            if selection.contains(number) {
                                selection.remove(number)
                            } else if selection.count < 6 {
                                selection.insert(number)
                            }
                        } label: {
                            NumberBall(number: number, marked: selection.contains(number))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(number)번")
                        .accessibilityAddTraits(selection.contains(number) ? .isSelected : [])
                    }
                }.lottoCard()
                if duplicate {
                    Text("이미 저장한 조합이에요.").font(.subheadline).foregroundStyle(LottoStyle.violet)
                }
                PrimaryLottoButton(label: "조합 저장", symbol: "bookmark.fill") {
                    let label = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(SavedLine(id: line.id, name: label.isEmpty ? "내 조합" : label, numbers: selection.sorted()))
                    dismiss()
                }.disabled(selection.count != 6 || duplicate)
                    .opacity(selection.count == 6 && !duplicate ? 1 : 0.5)
            }.padding(20)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .foregroundStyle(LottoStyle.ink)
        .background(LottoStyle.paper.ignoresSafeArea())
    }
}
