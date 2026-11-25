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

struct DrawPattern: Hashable {
    let odds: Int
    let sumBucket: Int
    let occupiedBands: Int
    let hasConsecutive: Bool

    init(sortedNumbers: [Int]) {
        odds = sortedNumbers.count { $0.isMultiple(of: 2) == false }
        sumBucket = (sortedNumbers.reduce(0, +) - 1) / 30
        occupiedBands = Set(sortedNumbers.map { ($0 - 1) / 10 }).count
        hasConsecutive = zip(sortedNumbers, sortedNumbers.dropFirst()).contains { $1 - $0 == 1 }
    }

    var sumRange: String { "\(sumBucket * 30 + 1)~\((sumBucket + 1) * 30)" }
}

struct PatternPick {
    let numbers: [Int]
    let pattern: DrawPattern
    let matchingRounds: Int
}

struct HistoricalPatterns {
    let roundCount: Int
    let occurrences: [DrawPattern: Int]
    let oddsCounts: [Int: Int]
    let sumCounts: [Int: Int]
    let bandCounts: [Int: Int]
    let consecutiveCount: Int

    init(draws: [Draw]) {
        let patterns = draws.map { DrawPattern(sortedNumbers: $0.numbers.sorted()) }
        roundCount = patterns.count
        occurrences = patterns.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        oddsCounts = patterns.reduce(into: [:]) { $0[$1.odds, default: 0] += 1 }
        sumCounts = patterns.reduce(into: [:]) { $0[$1.sumBucket, default: 0] += 1 }
        bandCounts = patterns.reduce(into: [:]) { $0[$1.occupiedBands, default: 0] += 1 }
        consecutiveCount = patterns.filter(\.hasConsecutive).count
    }

    func pick() -> PatternPick? {
        // Estimate the joint distribution from historical counts. Skip sparsely observed shapes
        // so a randomly generated combination with the selected shape stays practical to find.
        let minimum = max(1, (roundCount + 99) / 100)
        let eligible = occurrences.filter { $0.value >= minimum }
        let total = eligible.values.reduce(0, +)
        guard total > 0 else { return nil }

        var ticket = Int.random(in: 0..<total)
        for (pattern, count) in eligible {
            ticket -= count
            if ticket < 0 {
                for _ in 0..<4096 {
                    let numbers = LottoHistory.random()
                    if DrawPattern(sortedNumbers: numbers) == pattern {
                        return PatternPick(numbers: numbers, pattern: pattern, matchingRounds: count)
                    }
                }
                return nil
            }
        }
        return nil
    }
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
    let patterns: HistoricalPatterns

    init(draws: [Draw]) {
        self.draws = draws
        self.patterns = HistoricalPatterns(draws: draws)
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

    static func random() -> [Int] {
        // Floyd sampling chooses six distinct numbers uniformly without shuffling all 45.
        var numbers: Set<Int> = []
        for upperBound in 40...45 {
            let draw = Int.random(in: 1...upperBound)
            if !numbers.insert(draw).inserted { numbers.insert(upperBound) }
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
