import test from 'ava';
import fs from 'fs';
import path from 'path';
import JSON5 from 'json5';
import { parse } from '..';

function getSyntaxErrorIndicator(text, location) {
  const lno = location.start.line - 1;
  const cno = location.start.column - 1;
  const lines = text.split(/\n/);
  const indicator = Array.from(new Array(cno)).map(() => ' ').join('') + '^';
  return [
    ...lines.slice(0, lno + 1),
    indicator,
    ...lines.slice(lno + 1),
  ].slice(Math.max(lno - 2, 0), lno + 3).join('\n');
}

const PARSABLE_DIR = path.join(__dirname, 'data', 'parsable');
const EXPECTED_DIR = path.join(__dirname, 'data', 'expected');

fs.readdirSync(PARSABLE_DIR)
  .filter((filename) => /\.soql$/.test(filename))
  .forEach((filename) => {
    const name = path.basename(filename, '.soql');
    test(`parse soql test: ${name}`, (t) => {
      const soql = fs.readFileSync(path.join(PARSABLE_DIR, filename), 'utf8');
      const expected = JSON5.parse(
        fs.readFileSync(path.join(EXPECTED_DIR, `${name}.json5`), 'utf8')
      );
      let parsed;
      try {
        parsed = parse(soql);
      } catch (e) {
        let message = e.message;
        if (e.location) {
          const indicator = getSyntaxErrorIndicator(soql, e.location);
          message = `${message}\n\n[${name}]\n${indicator}`;
        }
        t.fail(message);
      }
      t.deepEqual(parsed, expected);
    });
  });
