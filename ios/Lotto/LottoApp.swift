import SwiftUI
import UIKit

@main
struct LottoApp: App {
    var body: some Scene { WindowGroup { LottoHome() } }
}

private enum LottoTab: String, CaseIterable {
    case saved = "내 번호"
    case random = "뽑기"
    case stats = "역대 통계"

    var symbol: String {
        switch self {
        case .saved: "bookmark"
        case .random: "sparkles"
        case .stats: "chart.bar.xaxis"
        }
    }
}

struct LottoHome: View {
    private let history = LottoHistory.bundled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage private var savedData: Data
    @State private var tab: LottoTab = .random
    @State private var result: [Int] = []
    @State private var recommendation: PatternPick?
    @State private var patternUnavailable = false
    @State private var reveal: DrawReveal?
    @State private var analysis: SavedLine?
    @State private var editor: SavedLine?
    @State private var pendingDelete: SavedLine?
    @State private var orderedByCount = true

    init() {
        var storageKey = "lotto.saved.v1"
        #if DEBUG
        if let testRun = ProcessInfo.processInfo.environment["LOTTO_UI_TEST_RUN"] {
            storageKey += ".test." + testRun
        }
        #endif
        _savedData = AppStorage(wrappedValue: Data(), storageKey)
    }

    private var saved: [SavedLine] { (try? JSONDecoder().decode([SavedLine].self, from: savedData)) ?? [] }
    private var resultIsSaved: Bool { saved.contains { $0.numbers == result } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                switch tab {
                case .random: randomScreen
                case .saved: savedScreen
                case .stats: statsScreen
                }
            }
            .padding(.horizontal, 21)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .id(tab)
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .background(LottoStyle.paper.ignoresSafeArea())
        .foregroundStyle(LottoStyle.ink)
        .preferredColorScheme(.light)
        .overlay {
            if let reveal {
                LottoCutscene(reveal: reveal)
                    .id(reveal.id)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .task(id: reveal?.id) {
            guard let id = reveal?.id else { return }
            try? await Task.sleep(for: .seconds(LottoCutscene.duration))
            guard !Task.isCancelled, reveal?.id == id else { return }
            reveal = nil
        }
        .sheet(item: $analysis) { line in
            AnalysisView(line: line, history: history)
        }
        .sheet(item: $editor) { line in
            NumberEditor(line: line, existing: saved, onSave: saveEdited)
        }
        .alert("이 조합을 삭제할까요?", isPresented: Binding(get: { pendingDelete != nil }, set: {
            if !$0 { pendingDelete = nil }
        })) {
            Button("취소", role: .cancel) { pendingDelete = nil }
            Button("삭제", role: .destructive) {
                if let pendingDelete { store(saved.filter { $0.id != pendingDelete.id }) }
                pendingDelete = nil
            }
        }
    }

    private var randomScreen: some View {
        Group {
            LottoHeading(title: "번호 뽑기", subtitle: "한 번 눌러 여섯 번호를 뽑아요.")
            LottoStage(numbers: result)
            PrimaryLottoButton(label: result.isEmpty ? "번호 뽑기" : "다시 뽑기", symbol: "sparkles", action: draw)
                .accessibilityIdentifier("quick-draw")
            if !result.isEmpty {
                HStack(spacing: 10) {
                    action(resultIsSaved ? "저장됨" : "내 번호에 저장", resultIsSaved ? "checkmark" : "bookmark") {
                        save(numbers: result)
                    }.disabled(resultIsSaved)
                    action("역대 비교", "arrow.up.right") { openAnalysis(result) }
                }
            }
        }
    }

    private var savedScreen: some View {
        Group {
            LottoHeading(title: "내 번호", subtitle: "자주 쓰는 조합을 역대 당첨번호와 비교해요.")
            if saved.isEmpty {
                VStack(alignment: .leading, spacing: 11) {
                    Image(systemName: "bookmark").font(.title2).foregroundStyle(LottoStyle.violet)
                    Text("아직 저장한 번호가 없어요").font(.headline)
                    Text("번호를 직접 고르거나 뽑기 결과를 저장해 보세요.")
                        .font(.subheadline).foregroundStyle(LottoStyle.muted)
                }.frame(maxWidth: .infinity, alignment: .leading).lottoCard()
            }
            ForEach(saved) { line in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(line.name).font(.headline)
                        Spacer()
                        Menu {
                            Button("수정", systemImage: "pencil") { editor = line }
                            Button("삭제", systemImage: "trash", role: .destructive) { pendingDelete = line }
                        } label: { Image(systemName: "ellipsis").padding(8) }
                            .accessibilityLabel("조합 옵션")
                    }
                    BallRow(numbers: line.numbers)
                    Button { analysis = line } label: {
                        Label("역대 회차 비교", systemImage: "arrow.up.right")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.top, 2).foregroundStyle(LottoStyle.violet)
                }.lottoCard()
            }
            PrimaryLottoButton(label: "번호 직접 추가", symbol: "plus") {
                editor = SavedLine(name: "", numbers: [])
            }
        }
    }

    private var statsScreen: some View {
        Group {
            LottoHeading(title: "역대 통계", subtitle: history.range)
            if !history.draws.isEmpty {
                patternPicker
                HistoricalPatternSummary(patterns: history.patterns)

                VStack(alignment: .leading, spacing: 12) {
                    Text("45개 번호의 출현 횟수").font(.title3.weight(.heavy))
                    Picker("정렬", selection: $orderedByCount) {
                        Text("횟수순").tag(true)
                        Text("번호순").tag(false)
                    }.pickerStyle(.segmented)
                    let ranking = history.ranking
                    let entries = orderedByCount ? ranking : ranking.sorted { $0.number < $1.number }
                    LazyVStack(spacing: 8) {
                        ForEach(entries) { item in
                            CountRow(number: item.number, count: item.count, maximum: ranking.first?.count ?? 1)
                        }
                    }
                }.lottoCard()
            }
        }
    }

    private var patternPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Label("패턴 뽑기", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.title2.weight(.black))
                Text("역대 조합의 홀짝, 합계, 번호대, 연속번호 구성을 따라 새 번호를 뽑아요.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.85))
            }
            if let pick = recommendation {
                BallRow(numbers: pick.numbers, stage: true)
                    .accessibilityIdentifier("pattern-result")
                PatternDetails(pattern: pick.pattern, sum: pick.numbers.reduce(0, +))
                Text("이 구성은 역대 \(pick.matchingRounds)회 나왔어요.")
                    .font(.subheadline.weight(.bold)).foregroundStyle(LottoStyle.lime)
                HStack(spacing: 10) {
                    let isSaved = saved.contains { $0.numbers == pick.numbers }
                    action(isSaved ? "저장됨" : "저장", "bookmark") { save(numbers: pick.numbers) }
                        .disabled(isSaved)
                    action("역대 비교", "arrow.up.right") { openAnalysis(pick.numbers) }
                }
            }
            if patternUnavailable {
                Text("조합을 만들지 못했어요. 한 번 더 눌러 주세요.")
                    .font(.subheadline).foregroundStyle(.white)
            }
            PrimaryLottoButton(label: "패턴으로 뽑기", symbol: "sparkles") {
                let pick = history.patterns.pick()
                patternUnavailable = pick == nil
                if let pick {
                    recommendation = pick
                    showCutscene(pick.numbers, title: "역대 패턴 조합")
                }
            }
            Text("공정 추첨에서는 모든 번호 조합의 당첨 확률이 같아요.")
                .font(.caption).foregroundStyle(.white.opacity(0.8))
        }
        .foregroundStyle(.white)
        .padding(17)
        .background(
            LinearGradient(colors: [LottoStyle.night, LottoStyle.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    private var tabBar: some View {
        HStack(spacing: 5) {
            ForEach(LottoTab.allCases, id: \.self) { page in
                Button { tab = page } label: {
                    VStack(spacing: 4) {
                        Image(systemName: page.symbol).font(.system(size: 19, weight: .semibold))
                        Text(page.rawValue).font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(tab == page ? LottoStyle.ink : LottoStyle.muted)
                    .background(tab == page ? LottoStyle.lime : .clear, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == page ? .isSelected : [])
            }
        }
        .padding(.horizontal, 19).padding(.top, 9).padding(.bottom, 5)
        .background(LottoStyle.paper)
        .overlay(alignment: .top) { Rectangle().fill(LottoStyle.line).frame(height: 1) }
    }

    private func draw() {
        result = LottoHistory.random()
        showCutscene(result, title: "오늘의 여섯 번호")
    }

    private func showCutscene(_ numbers: [Int], title: String) {
        if !reduceMotion { reveal = DrawReveal(numbers: numbers, title: title) }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func action(_ label: String, _ symbol: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(label, systemImage: symbol)
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(LottoStyle.ink)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(LottoStyle.line))
        }.buttonStyle(.plain)
    }

    private func store(_ lines: [SavedLine]) {
        if let data = try? JSONEncoder().encode(lines) { savedData = data }
    }

    private func save(numbers: [Int]) {
        guard LottoHistory.valid(numbers), !saved.contains(where: { $0.numbers == numbers }) else { return }
        store(saved + [SavedLine(name: "내 조합", numbers: numbers)])
    }

    private func saveEdited(_ line: SavedLine) {
        var lines = saved
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            lines[index] = line
        } else {
            lines.append(line)
        }
        store(lines)
    }

    private func openAnalysis(_ numbers: [Int]) {
        analysis = saved.first { $0.numbers == numbers } ?? SavedLine(name: "이 조합", numbers: numbers)
    }
}
