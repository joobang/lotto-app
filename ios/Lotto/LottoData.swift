import Foundation

struct Draw: Decodable, Identifiable {
    let round: Int
    let drawDate: String
    let numbers: [Int]
    let bonus: Int
    var id: Int { round }
}

struct SavedLine: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var numbers: [Int]
}

struct NumberCount: Identifiable {
    let number: Int
    let count: Int
    var id: Int { number }
}

struct DrawMatch: Identifiable {
    let draw: Draw
    let hits: Set<Int>
    var id: Int { draw.round }
}

struct DrawAnalysis {
    let matches: [DrawMatch]
    let distribution: [Int]
    let pairs: [(first: Int, second: Int, count: Int)]
    var best: Int { distribution.lastIndex(where: { $0 > 0 }) ?? 0 }
    var bestCount: Int { distribution[best] }
}

struct LottoHistory {
    private struct Seed: Decodable { let draws: [Draw] }

    static let bundled: LottoHistory = {
        guard let url = Bundle.main.url(forResource: "initial-draws", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seed = try? JSONDecoder().decode(Seed.self, from: data),
              seed.draws.enumerated().allSatisfy({ $0.element.round == $0.offset + 1 && valid($0.element.numbers) })
        else { return LottoHistory(draws: []) }
        return LottoHistory(draws: seed.draws)
    }()

    let draws: [Draw]
    let counts: [Int: Int]

    init(draws: [Draw]) {
        self.draws = draws
        self.counts = draws.flatMap(\.numbers).reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    var range: String { draws.last.map { "1~\($0.round)회 이력" } ?? "역대 이력 준비 중" }
    var ranking: [NumberCount] {
        (1...45).map { NumberCount(number: $0, count: counts[$0, default: 0]) }
            .sorted { $0.count == $1.count ? $0.number < $1.number : $0.count > $1.count }
    }

    static func valid(_ numbers: [Int]) -> Bool {
        numbers.count == 6 && Set(numbers).count == 6 && numbers.allSatisfy { (1...45).contains($0) }
    }

    static func random() -> [Int] { Array((1...45).shuffled().prefix(6)).sorted() }

    func frequencyDraw() -> [Int] {
        var pool = Array(1...45)
        var numbers: [Int] = []
        for _ in 0..<6 {
            let total = pool.reduce(0) { $0 + counts[$1, default: 0] + 1 }
            var ticket = Int.random(in: 0..<total)
            for (index, number) in pool.enumerated() {
                ticket -= counts[number, default: 0] + 1
                if ticket < 0 {
                    numbers.append(pool.remove(at: index))
                    break
                }
            }
        }
        return numbers.sorted()
    }

    func analyze(_ numbers: [Int]) -> DrawAnalysis {
        let selected = Set(numbers)
        var distribution = Array(repeating: 0, count: 7)
        var matches: [DrawMatch] = []
        for draw in draws {
            let hits = selected.intersection(draw.numbers)
            distribution[hits.count] += 1
            if !hits.isEmpty { matches.append(DrawMatch(draw: draw, hits: hits)) }
        }
        matches.sort { $0.hits.count == $1.hits.count ? $0.id > $1.id : $0.hits.count > $1.hits.count }
        let pairs = numbers.enumerated().flatMap { index, first in
            numbers.dropFirst(index + 1).map { second in
                (first, second, matches.count { $0.hits.contains(first) && $0.hits.contains(second) })
            }
        }.sorted {
            if $0.2 != $1.2 { return $0.2 > $1.2 }
            return $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 < $1.0
        }
        return DrawAnalysis(matches: Array(matches.prefix(10)), distribution: distribution, pairs: pairs)
    }
}
