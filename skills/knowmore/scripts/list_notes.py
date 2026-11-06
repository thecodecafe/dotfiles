#!/usr/bin/env python3
"""Read-only status listings for Knowmore's local Markdown notes."""

import argparse
from datetime import datetime, timezone
from pathlib import Path
import re
import sys


USAGE = ('Use introduced, working on, or familiar, optionally followed by '
         '<order by: most recent|oldest first, limit: positive integer>.')
STATUSES = ('introduced', 'working on', 'familiar')
COLUMNS = ('Term or concept', 'Domain', 'Status', 'Context or learning signal')


def parse_query(query):
    match = re.fullmatch(r'(introduced|working on|familiar)(?:\s*(<[^<>]*>))?', query.strip())
    if not match:
        raise ValueError('Invalid listing command or filter brackets.')
    status, block = match.groups()
    options = {}
    if block is not None:
        for pair in block[1:-1].split(','):
            key, colon, value = pair.partition(':')
            key, value = key.strip(), value.strip()
            if not colon or key not in ('order by', 'limit'):
                raise ValueError('Filters must use order by or limit with key: value syntax.')
            if key in options:
                raise ValueError(f'Duplicate filter: {key}.')
            options[key] = value
    order = options.get('order by', 'most recent')
    if order not in ('most recent', 'oldest first'):
        raise ValueError('order by must be most recent or oldest first.')
    limit = options.get('limit')
    if limit is not None:
        if not re.fullmatch(r'[0-9]+', limit) or int(limit) <= 0:
            raise ValueError('limit must be a positive whole number.')
        limit = int(limit)
    return status, order, limit


def cells(line):
    return [cell.strip().replace(r'\|', '|')
            for cell in re.split(r'(?<!\\)\|', line.strip()[1:-1])]


def read_notes(notes):
    if not notes.exists():
        return []
    header = None
    entries = []
    for number, line in enumerate(notes.read_text().splitlines(), 1):
        if not line.strip().startswith('|'):
            continue
        if not line.strip().endswith('|'):
            raise ValueError(f'Incomplete notes table at line {number}.')
        row = cells(line)
        if header is None:
            if set(COLUMNS).issubset(row):
                if len(set(row)) != len(row):
                    raise ValueError('Duplicate notes table columns.')
                header = row
            continue
        if all(re.fullmatch(r':?-+:?', cell) for cell in row):
            continue
        if len(row) != len(header):
            raise ValueError(f'Wrong number of notes columns at line {number}.')
        entry = dict(zip(header, row))
        entry['Status'] = entry['Status'].strip('*`')
        if entry['Status'] not in STATUSES:
            raise ValueError(f'Unknown learning status at line {number}.')
        updated = entry.get('Updated at', '')
        timestamp = None
        if updated not in ('', 'unknown'):
            try:
                timestamp = datetime.fromisoformat(updated.replace('Z', '+00:00'))
                if timestamp.tzinfo is None or timestamp.utcoffset() is None:
                    raise ValueError('timestamp requires a timezone')
                timestamp = timestamp.astimezone(timezone.utc)
            except ValueError:
                raise ValueError(f'Invalid Updated at timestamp at line {number}.') from None
        entry['timestamp'] = timestamp
        entries.append(entry)
    if header is None:
        raise ValueError('Learning notes do not contain the expected table columns.')
    return entries


def render(entries, status, order, limit):
    matching = [entry for entry in entries if entry['Status'] == status]
    dated = sorted((entry for entry in matching if entry['timestamp'] is not None),
                   key=lambda entry: entry['timestamp'], reverse=order == 'most recent')
    unknown = [entry for entry in matching if entry['timestamp'] is None]
    selected = (dated + unknown)[:limit]
    if not selected:
        return f'No concepts recorded as "{status}".'
    lines = ['| Concept | Domain | Learning context | Updated at |',
             '| --- | --- | --- | --- |']
    for entry in selected:
        updated = (entry['timestamp'].isoformat().replace('+00:00', 'Z')
                   if entry['timestamp'] is not None else 'unknown')
        values = [entry[COLUMNS[0]], entry[COLUMNS[1]], entry[COLUMNS[3]], updated]
        lines.append('| ' + ' | '.join(value.replace('|', r'\|') for value in values) + ' |')
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--query', required=True, help=USAGE)
    parser.add_argument('--notes', type=Path,
                        default=Path(__file__).resolve().parents[1] / 'learning-notes.md')
    args = parser.parse_args()
    try:
        status, order, limit = parse_query(args.query)
        print(render(read_notes(args.notes), status, order, limit))
    except (OSError, UnicodeError, ValueError) as error:
        print(f'Error: {error}\n{USAGE}', file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
