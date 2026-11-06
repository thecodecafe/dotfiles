#!/usr/bin/env python3
"""Exercise Knowmore listing behavior using isolated learning records."""

from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest


HELPER = Path(__file__).resolve().parents[1] / 'skills/knowmore/scripts/list_notes.py'
NOTES = '''# Learning notes

| Term or concept | Domain | Status | Context or learning signal | Updated at |
| --- | --- | --- | --- | --- |
| Legacy | General | introduced | Historical entry | unknown |
| Earlier | Git | introduced | First example | 2026-11-01T12:00:00Z |
| Recent | Shell | **introduced** | Pipe \\| example | 2026-11-06T12:00:00Z |
| Tie | General | introduced | Equal timestamp | 2026-11-06T12:00:00Z |
| Practice | Git | working on | Asked for help | 2026-11-05T12:00:00Z |
| Known | Shell | familiar | Used accurately | 2026-11-04T12:00:00Z |
'''


class KnowmoreListings(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory(prefix='knowmore-test-')
        self.addCleanup(self.temp.cleanup)
        self.notes = Path(self.temp.name) / 'learning-notes.md'
        self.notes.write_text(NOTES)

    def query(self, text, expected_code=0):
        before = (self.notes.read_bytes(), self.notes.stat().st_mtime_ns)
        result = subprocess.run([sys.executable, str(HELPER), '--notes', str(self.notes),
                                 '--query', text], capture_output=True, text=True)
        self.assertEqual(result.returncode, expected_code, result.stderr)
        self.assertEqual((self.notes.read_bytes(), self.notes.stat().st_mtime_ns), before)
        return result

    def concepts(self, query):
        return [line.split('|')[1].strip() for line in self.query(query).stdout.splitlines()[2:]]

    def test_statuses_and_stable_default_order(self):
        self.assertEqual(self.concepts('introduced'), ['Recent', 'Tie', 'Earlier', 'Legacy'])
        self.assertEqual(self.concepts('working on'), ['Practice'])
        self.assertEqual(self.concepts('familiar'), ['Known'])
        self.assertIn(r'Pipe \| example', self.query('introduced').stdout)

    def test_sort_then_limit_and_unknown_dates_last(self):
        self.assertEqual(self.concepts('introduced <order by: oldest first>'),
                         ['Earlier', 'Recent', 'Tie', 'Legacy'])
        self.assertEqual(self.concepts('introduced <limit: 2, order by: most recent>'),
                         ['Recent', 'Tie'])
        self.assertEqual(self.concepts('introduced <order by: oldest first, limit: 1>'),
                         ['Earlier'])

    def test_legacy_records_without_dates(self):
        self.notes.write_text('| Term or concept | Domain | Status | Context or learning signal |\n'
                              '| --- | --- | --- | --- |\n'
                              '| Legacy | General | introduced | No historical date |\n')
        self.assertIn('| unknown |', self.query('introduced').stdout)
        self.assertIn('No concepts recorded', self.query('familiar').stdout)

    def test_empty_records_and_missing_file(self):
        self.notes.write_text('\n'.join(NOTES.splitlines()[:4]) + '\n')
        self.assertIn('No concepts recorded', self.query('working on').stdout)
        self.notes.unlink()
        result = subprocess.run([sys.executable, str(HELPER), '--notes', str(self.notes),
                                 '--query', 'introduced'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.notes.exists())

    def test_invalid_filters_never_write(self):
        for query in ('', 'on', 'introducts', 'introduced <>', 'introduced <<limit: 2>>',
                      'introduced <limit: 2', 'introduced <limit: 2> extra',
                      'introduced <domain: Git>', 'introduced <limit: 1, limit: 2>',
                      'introduced <limit: 0>', 'introduced <limit: -1>',
                      'introduced <limit: 1.5>', 'introduced <order by: newest>',
                      'introduced <Order by: most recent>', 'introduced <limit 2>'):
            with self.subTest(query=query):
                self.assertIn('Error:', self.query(query, expected_code=2).stderr)

    def test_malformed_records_are_reported(self):
        for contents in ('unrecognized notes', NOTES.replace('2026-11-01T12:00:00Z', 'yesterday'),
                         NOTES.replace('2026-11-01T12:00:00Z', '2026-11-01T12:00:00'),
                         NOTES.replace('| Git | introduced |', '| introduced |')):
            with self.subTest(contents=contents):
                self.notes.write_text(contents)
                self.assertIn('Error:', self.query('introduced', expected_code=2).stderr)


if __name__ == '__main__':
    unittest.main()
