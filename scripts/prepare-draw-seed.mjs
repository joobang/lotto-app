import { writeFile } from 'node:fs/promises';

const historyUrl = 'https://papaya5rhw1984.github.io/lotto-data/all.json';
const comparisonUrl = 'https://busebu.com/lotto/draws.json';
const lastRound = 1251;
const officialLatest = { drawDate: '2026-11-21', numbers: [14, 18, 19, 29, 40, 45], bonus: 1 };

async function readJson(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
  if (!response.ok) throw new Error(`Source returned HTTP ${response.status}`);
  return response.json();
}

function validDraw(draw) {
  const day = new Date(draw.drawDate);
  return Number.isInteger(draw.round) && draw.round > 0 &&
    /^\d{4}-\d{2}-\d{2}$/.test(draw.drawDate) && Number.isFinite(day.valueOf()) &&
    day.toISOString().slice(0, 10) === draw.drawDate &&
    draw.numbers.length === 6 && new Set([...draw.numbers, draw.bonus]).size === 7 &&
    [...draw.numbers, draw.bonus].every(number => Number.isInteger(number) && number >= 1 && number <= 45);
}

function matches(left, right) {
  return left.drawDate === right.drawDate && left.bonus === right.bonus &&
    left.numbers.every((number, index) => number === right.numbers[index]);
}

const output = process.argv[2];
if (!output) throw new Error('Specify a new output JSON path');
const [history, comparison] = await Promise.all([readJson(historyUrl), readJson(comparisonUrl)]);
const draws = history.filter(row => row.draw_no <= lastRound).map(row => ({
  round: row.draw_no,
  drawDate: row.date.slice(0, 10),
  numbers: [...row.numbers].sort((a, b) => a - b),
  bonus: row.bonus_no,
  sourceUrl: historyUrl,
})).sort((a, b) => a.round - b.round);
if (draws.length !== lastRound || draws.some((draw, index) => draw.round !== index + 1 ||
    !validDraw(draw) || index > 0 && draw.drawDate <= draws[index - 1].drawDate))
  throw new Error('Initial draw sequence is invalid');
if (!matches(draws.at(-1), officialLatest)) throw new Error('Latest draw differs from the official reference');
draws.at(-1).sourceUrl = 'https://www.dhlottery.co.kr/lt645/result?ltEpsd=1251';

const comparedRounds = new Set();
for (const row of comparison.filter(item => item.drwNo <= lastRound)) {
  const draw = {
    round: row.drwNo,
    drawDate: row.drwNoDate,
    numbers: Array.from({ length: 6 }, (_, index) => row[`drwtNo${index + 1}`]).sort((a, b) => a - b),
    bonus: row.bnusNo,
  };
  if (!validDraw(draw) || !matches(draws[draw.round - 1], draw) || comparedRounds.has(draw.round))
    throw new Error(`Comparison differs at round ${draw.round}`);
  comparedRounds.add(draw.round);
}
if (comparedRounds.size < 1249) throw new Error('Comparison covers fewer than 1249 rounds');
await writeFile(output, JSON.stringify({ draws }, null, 2) + '\n', { flag: 'wx' });
console.log(JSON.stringify({ firstRound: 1, lastRound, drawCount: draws.length, comparedRounds: comparedRounds.size }));
