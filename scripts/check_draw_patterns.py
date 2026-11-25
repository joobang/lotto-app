#!/usr/bin/env python3
"""Reproduce historical pattern counts and the held-out hot-number comparison."""
import json
from collections import Counter
from itertools import product
from math import comb, prod
from pathlib import Path
from random import Random

data = Path(__file__).resolve().parents[1] / "data" / "initial-draws.json"
draws = [sorted(draw["numbers"]) for draw in json.loads(data.read_text())["draws"]]
assert len(draws) > 1_000
total = comb(45, 6)
odds = Counter(sum(n % 2 for n in line) for line in draws)
adjacent = sum(any(b - a == 1 for a, b in zip(line, line[1:])) for line in draws)
sums = Counter((sum(line) - 1) // 30 for line in draws)
occupied = Counter(len({(n - 1) // 10 for n in line}) for line in draws)
repeat = Counter(len(set(a) & set(b)) for a, b in zip(draws, draws[1:]))

training, holdout = draws[:1000], draws[1000:]
training_counts = Counter(n for line in training for n in line)
hot = set(sorted(range(1, 46), key=lambda n: (-training_counts[n], n))[:6])
hot_overlap = sum(len(hot & set(line)) for line in holdout) / len(holdout)

# Exact uniform-draw references, computed without using the historical sample.
possible_sums = [Counter({0: 1})] + [Counter() for _ in range(6)]
for n in range(1, 46):
    for picked in range(6, 0, -1):
        possible_sums[picked].update({subtotal + n: ways for subtotal, ways in possible_sums[picked - 1].items()})
sum_reference = sum(possible_sums[6][score] for score in range(121, 151)) / total
four_band_reference = sum(
    prod(comb(size, count) for size, count in zip((10, 10, 10, 10, 5), allocation))
    for allocation in product(range(7), repeat=5)
    if sum(allocation) == 6 and sum(count > 0 for count in allocation) == 4
) / total

print(f"Rounds: {len(draws)}")
print(f"3 odd + 3 even: {odds[3]} ({odds[3] / len(draws):.2%}) / theoretical {comb(23, 3) * comb(22, 3) / total:.2%}")
print(f"Any consecutive pair: {adjacent} ({adjacent / len(draws):.2%}) / theoretical {1 - comb(40, 6) / total:.2%}")
print("Sum buckets (start–end, count):", [(key * 30 + 1, (key + 1) * 30, count) for key, count in sums.most_common()])
print(f"Sum 121–150: {sums[4]} ({sums[4] / len(draws):.2%}) / theoretical {sum_reference:.2%}")
print("Occupied number bands:", occupied.most_common())
print(f"Four bands: {occupied[4]} ({occupied[4] / len(draws):.2%}) / theoretical {four_band_reference:.2%}")
print("Previous round overlap:", sorted(repeat.items()))
print(f"Held out {len(holdout)} rounds. Train top six: {sorted(hot)}. Mean overlap {hot_overlap:.3f} vs. uniform expectation {6 * 6 / 45:.3f}")


weights = {n: training_counts[n] + 1 for n in range(1, 46)}
holdout_counts = Counter(n for line in holdout for n in line)
rng = Random(45)
weighted_overlap = 0
trials = 20_000
for _ in range(trials):
    remaining = dict(weights)
    for _ in range(6):
        ticket = rng.randrange(sum(remaining.values()))
        for number, weight in remaining.items():
            ticket -= weight
            if ticket < 0:
                weighted_overlap += holdout_counts[number]
                del remaining[number]
                break
print(f"Previous weighted sampler: mean overlap {weighted_overlap / (len(holdout) * trials):.3f} (seeded simulation)")
