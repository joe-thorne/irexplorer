"""Private researcher export, SQLite backup/restore, and retention operations."""
import argparse
import csv
import json
import os
from pathlib import Path
import sqlite3

from .content import participant_content
from .service import Config, canonical


def private_path(path):
    path = Path(path).resolve()
    Config(path.parent)  # Reject public/project output locations.
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    return path


def open_db(path):
    db = sqlite3.connect(f'{Path(path).resolve().as_uri()}?mode=ro', uri=True)
    if db.execute('PRAGMA user_version').fetchone()[0] != 1 or db.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
        db.close()
        raise ValueError('Unsupported or damaged study database')
    return db


def backup(source, destination):
    destination = private_path(destination)
    # Exclusive creation prevents an accidental overwrite of a live database.
    fd = os.open(destination, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    os.close(fd)
    src = dst = None
    try:
        src = open_db(source)
        dst = sqlite3.connect(destination)
        src.backup(dst)
    except Exception:
        destination.unlink()
        raise
    finally:
        if src: src.close()
        if dst: dst.close()


def safe_cell(value):
    if isinstance(value, (dict, list)):
        value = canonical(value)
    if isinstance(value, str) and (value.lstrip().startswith(('=', '+', '-', '@')) or value.startswith(('\t', '\r', '\n'))):
        return "'" + value
    return value


def export(source, directory):
    directory = private_path(Path(directory) / 'placeholder').parent
    db = open_db(source)
    try:
        records = [{'response': json.loads(p), 'receipt': json.loads(r), 'release': json.loads(v)} for p, r, v in db.execute('SELECT payload, receipt, release FROM responses ORDER BY submission_id')]
    finally:
        db.close()
    def write(name, value):
        path = directory / name
        with open(path, 'x', encoding='utf-8') as f:
            os.chmod(path, 0o600)
            json.dump(value, f, ensure_ascii=False, indent=2)
    write('responses.json', records)
    content = participant_content()
    write('codebook.json', {
        'schemaVersion': 1, 'fields': content['fields'], 'scales': content['scales'],
        'versions': {k: content[k] for k in ('studyVersion', 'instrumentVersion', 'contentVersion')},
        'csv': 'Long format; value is the raw numeric code, JSON array, or text. Empty value with status is missing, never zero. Formula-like strings have a leading apostrophe; JSON preserves original text.',
        'durationMs': 'Rounded once to nearest integer millisecond at submission; 0–86400000. Active visible reading, exploration, and answering; excludes hidden tabs, explicit pause, and reload downtime. Not pure comprehension time. T1c is T1 durationMs.',
        'interrupted': 'Coarse pause/hide/route/recovery flag, not an event log. Abrupt termination may lose time since the last successful one-second checkpoint.',
        'taskStatus': ['completed', 'skipped', 'could_not_work_out'],
        'answerStatus': ['answered', 'unanswered', 'could_not_work_out', 'not_applicable'],
        'analysis': 'Raw ratings unchanged. In a separate analysis transformation use 6-value for answered Q3, Q8, Q10 only. Pair P13/Q14 by participantCode; count unanswered and not_applicable separately. Skipped/inability tasks retain partial responses. No automatic correctness coding. Incomplete/abandoned sessions are excluded.',
        'coding': 'Keep researcher coding in a separate file joined on participantCode and item/task ID. Resolve P3 completed/current, overlapping strata, and missing-data rules before analysis.',
    })
    columns = ['participantCode', 'submissionId', 'receiptId', 'studyVersion', 'contentVersion', 'instrumentVersion', 'consentVersion', 'schemaVersion', 'canonicalVersion', 'mode', 'appRevision', 'artefactSha256', 'stage', 'itemId', 'status', 'value', 'durationMs', 'interrupted']
    path = directory / 'responses.csv'
    with open(path, 'x', encoding='utf-8', newline='') as f:
        os.chmod(path, 0o600)
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for record in records:
            p = record['response']
            base = {k: p[k] for k in ('participantCode', 'submissionId', 'studyVersion', 'contentVersion', 'instrumentVersion')}
            base['consentVersion'] = p['consent']['version']
            base.update(record['release']); base['receiptId'] = record['receipt']['receiptId']
            def row(**values):
                writer.writerow({k: safe_cell(v) for k, v in {**base, **values}.items()})
            for key, value in p['consent']['acknowledgements'].items():
                row(stage='consent', itemId=key, status='acknowledged', value=value)
            for stage in ('pre', 'post'):
                for key, answer in p[stage].items():
                    row(stage=stage, itemId=key, **answer)
            for t in p['tasks']:
                row(stage=t['id'], itemId=t['id'], status=t['status'], durationMs=t['durationMs'], interrupted=t['interrupted'])
                for key, answer in t['answers'].items():
                    row(stage=t['id'], itemId=key, **answer)
    return len(records)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    for name in ('export', 'backup', 'restore'):
        p = sub.add_parser(name); p.add_argument('source', type=Path); p.add_argument('destination', type=Path)
    p = sub.add_parser('delete-participant'); p.add_argument('source', type=Path); p.add_argument('participant_code'); p.add_argument('--confirm', action='store_true', required=True)
    p = sub.add_parser('purge'); p.add_argument('paths', type=Path, nargs='+'); p.add_argument('--confirm', action='store_true', required=True)
    args = parser.parse_args()
    try:
        if args.command == 'export':
            print(f'Exported {export(args.source, args.destination)} sessions.')
        elif args.command in ('backup', 'restore'):
            backup(args.source, args.destination)
            check = open_db(args.destination); check.close()
            print('Verified copy complete. Keep collection stopped during restore.')
        elif args.command == 'delete-participant':
            check = open_db(args.source); check.close()
            db = sqlite3.connect(args.source)
            try:
                db.execute('PRAGMA secure_delete=ON')
                with db:
                    rows = db.execute('SELECT submission_id, payload FROM responses').fetchall()
                    ids = [(sid,) for sid, p in rows if json.loads(p)['participantCode'] == args.participant_code]
                    db.executemany('DELETE FROM responses WHERE submission_id=?', ids)
                db.execute('VACUUM')
            finally: db.close()
            print(f'Deleted {len(ids)} records. Apply deletion to backups and replace exports separately.')
        else:
            for path in args.paths:
                path = private_path(path)
                if path.suffix not in ('.sqlite3', '.json', '.csv'):
                    raise ValueError('Only explicit study database/export files can be purged')
                path.unlink()
                if path.suffix == '.sqlite3':
                    for suffix in ('-wal', '-shm', '-journal'):
                        Path(str(path) + suffix).unlink(missing_ok=True)
            print('Named files removed. Check backup, export, and host snapshot inventory.')
    except (OSError, ValueError, sqlite3.Error):
        parser.exit(1, 'Operation failed. Check private paths, schema, permissions, and destination existence.\n')


if __name__ == '__main__':
    main()
