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
    @State private var recommendation: [Int] = []
    @State private var shining = false
    @State private var pulse: Task<Void, Never>?
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
            LottoStage(numbers: result, shine: shining)
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("다음 조합").font(.title2.weight(.black))
                    Text("역대에 자주 나온 번호에 가중치를 줘요.")
                        .font(.subheadline).foregroundStyle(LottoStyle.muted)
                    if !recommendation.isEmpty {
                        BallRow(numbers: recommendation)
                        HStack(spacing: 10) {
                            action(saved.contains { $0.numbers == recommendation } ? "저장됨" : "저장", "bookmark") {
                                save(numbers: recommendation)
                            }.disabled(saved.contains { $0.numbers == recommendation })
                            action("역대 비교", "arrow.up.right") { openAnalysis(recommendation) }
                        }
                    }
                    PrimaryLottoButton(label: "통계로 뽑기", symbol: "chart.bar.fill") {
                        recommendation = history.frequencyDraw()
                    }
                }.lottoCard()

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
        // Replace the full result before starting the independent decorative animation.
        result = LottoHistory.random()
        pulse?.cancel()
        if !reduceMotion {
            shining = true
            pulse = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(70))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.17)) { shining = false }
            }
        }
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
