"""Standalone verification of the expanded public participant package."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from src.backend.evaluation import content as participant_content_module
from src.backend.evaluation.content import canonical_bytes, load_participant_package


def package_fixture():
    fields = [
        {'id': 'C1', 'prompt': 'I agree.', 'type': 'boolean', 'required': True,
         'presentation': {'control': 'checkbox'}},
        {'id': 'P1', 'prompt': 'Choose one.', 'type': 'single', 'required': True,
         'options': [{'value': 1, 'label': 'One'}], 'presentation': {'control': 'radio'}},
        {'id': 'Q1', 'prompt': 'Rate this.', 'type': 'rating', 'required': False,
         'scale': 'agreement', 'presentation': {'control': 'radio'}},
    ]
    content = {
        'instrumentVersion': 'v1', 'contentVersion': 'v1-preview-1', 'studyVersion': 'v1-synthetic-1',
        'scales': {'agreement': [{'value': 1, 'label': 'Agree'}]}, 'fields': fields,
        'preSections': [{'id': 'pre.section1', 'title': 'Background', 'fields': ['P1']}],
        'postSections': [{'id': 'post.section1', 'title': 'Survey', 'fields': ['Q1']}],
        'tasks': [{'id': 'T0', 'fields': [], 'title': 'Orientation', 'goal': 'Start.',
                   'instructions': 'Continue.', 'setup': {}, 'entryWorkspace': {
                       'example': 'score', 'left': {'ordinal': 0, 'view': 'ir'},
                       'right': {'ordinal': 0, 'view': 'ir'}, 'selection': 'clear'}}], 'taskIntroduction': [],
        'information': [{'id': 'information1', 'title': 'Study', 'blocks': [
            {'id': 'purpose', 'kind': 'paragraph', 'role': 'study-purpose', 'text': 'Purpose.'},
            {'id': 'submission', 'kind': 'paragraph', 'role': 'submission-guidance', 'text': 'Submission.'},
        ]}],
        'membership': {'consent': ['C1'], 'pre.section1': ['P1'], 'post.section1': ['Q1'],
                       'T0': [], 'pre': ['P1'], 'post': ['Q1']},
        'journey': {'sectionOrder': ['information', 'pre', 'tasks', 'post', 'review', 'receipt'],
                    'taskOrder': ['T0'], 'introductions': {'pre': 'Pre.', 'post': 'Post.'},
                    'timingPolicy': {'measure': 'task-presentation-duration', 'starts': 'presentation',
                                     'includes': ['visible-reading'], 'excludes': ['paused'], 'timeLimit': None,
                                     'setupReachedCollected': False}},
        'glossary': [], 'messages': {},
    }
    identity = {'identityVersion': 1, 'algorithm': 'sha256', 'canonicalisation': 'sorted-json-utf8-v1',
                'canonicalisationVersion': 1, 'digest': '', 'instrumentVersion': 'v1',
                'contentVersion': 'v1-preview-1', 'studyVersion': 'v1-synthetic-1'}
    package = {'packageSchemaVersion': 2, 'identity': identity, 'content': content}
    identity['digest'] = hashlib.sha256(canonical_bytes({
        'packageSchemaVersion': package['packageSchemaVersion'], 'content': content,
    })).hexdigest()
    return package


def rehash(package):
    package['identity']['digest'] = hashlib.sha256(canonical_bytes({
        'packageSchemaVersion': package['packageSchemaVersion'], 'content': package['content'],
    })).hexdigest()
    return package


class PublicPackageTests(unittest.TestCase):
    def write_pair(self, directory, package):
        package_path = Path(directory) / 'participant-package-v2.json'
        manifest_path = Path(directory) / 'public-manifest.json'
        package_bytes = json.dumps(package, ensure_ascii=False, indent=2).encode('utf-8') + b'\n'
        package_path.write_bytes(package_bytes)
        manifest = {'manifestSchemaVersion': 1, 'packageSchemaVersion': 2,
                    'identity': package['identity'],
                    'artifact': {'file': package_path.name,
                                 'sha256': hashlib.sha256(package_bytes).hexdigest()}}
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False) + '\n')
        return package_path, manifest_path

    def test_loads_canonical_identity_and_exact_public_file_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            package_path, manifest_path = self.write_pair(directory, package_fixture())
            package = load_participant_package(package_path, manifest_path)
        self.assertEqual(package['identity']['contentVersion'], 'v1-preview-1')
        self.assertEqual(package['content']['membership']['pre'], ['P1'])

    def test_application_caches_verified_package_and_returns_immutable_copies(self):
        participant_content_module._installed_package.cache_clear()
        with patch.object(participant_content_module, 'load_participant_package',
                          wraps=load_participant_package) as loader:
            first = participant_content_module.participant_content()
            first['fields'][0]['prompt'] = 'Changed caller copy'
            second = participant_content_module.participant_content()
            self.assertEqual(loader.call_count, 1)
            self.assertEqual(
                second['fields'][0]['prompt'],
                'I have read the information above and I understand what taking part involves.',
            )

    def test_rejects_missing_mismatched_or_noncanonical_package(self):
        with tempfile.TemporaryDirectory() as directory:
            package_path, manifest_path = self.write_pair(directory, package_fixture())
            package_path.write_bytes(package_path.read_bytes().replace(b'Purpose.', b'Purpose!'))
            with self.assertRaisesRegex(ValueError, 'manifest'):
                load_participant_package(package_path, manifest_path)

        with tempfile.TemporaryDirectory() as directory:
            package_path, manifest_path = self.write_pair(directory, package_fixture())
            manifest_path.unlink()
            with self.assertRaisesRegex(ValueError, 'together'):
                load_participant_package(package_path, manifest_path)

        with tempfile.TemporaryDirectory() as directory:
            package = package_fixture()
            package['content']['privateMapping'] = {'expected': 1}
            rehash(package)
            package_path, manifest_path = self.write_pair(directory, package)
            with self.assertRaisesRegex(ValueError, 'content schema'):
                load_participant_package(package_path, manifest_path)

    def test_finished_marker_is_covered_by_the_digest_and_mirrored_in_the_identity(self):
        def finished(content_marker=True, identity_marker=True):
            package = package_fixture()
            for key, value in (('contentVersion', 'v1-final-1'), ('studyVersion', 'v1-study-1')):
                package['content'][key] = package['identity'][key] = value
            if content_marker is not None:
                package['content']['finished'] = content_marker
            if identity_marker is not None:
                package['identity']['finished'] = identity_marker
            return rehash(package)

        with tempfile.TemporaryDirectory() as directory:
            package = load_participant_package(*self.write_pair(directory, finished()))
        self.assertIs(package['identity']['finished'], True)
        self.assertIs(package['content']['finished'], True)
        self.assertNotIn('finished', package_fixture()['identity'])

        for label, tampered in (
            ('identity only', finished(content_marker=None)),
            ('content only', finished(identity_marker=None)),
            ('false', finished(False, False)),
            ('text', finished('true', 'true')),
        ):
            with (self.subTest(label=label), tempfile.TemporaryDirectory() as directory,
                  self.assertRaisesRegex(ValueError, 'finished marker')):
                load_participant_package(*self.write_pair(directory, tampered))

        # The digest covers the marker: dropping it from the content leaves a stale identity.
        with tempfile.TemporaryDirectory() as directory:
            stale = finished()
            del stale['content']['finished'], stale['identity']['finished']
            with self.assertRaisesRegex(ValueError, 'canonical identity'):
                load_participant_package(*self.write_pair(directory, stale))

    def test_rejects_nested_private_field_metadata_after_recomputing_all_hashes(self):
        with tempfile.TemporaryDirectory() as directory:
            package = package_fixture()
            package['content']['fields'][1]['rubric'] = 'PRIVATE_SENTINEL'
            rehash(package)
            package_path, manifest_path = self.write_pair(directory, package)
            with self.assertRaisesRegex(ValueError, 'field P1'):
                load_participant_package(package_path, manifest_path)

    def test_accepts_declared_short_text_input_control(self):
        with tempfile.TemporaryDirectory() as directory:
            package = package_fixture()
            field = package['content']['fields'][1]
            field.pop('options')
            field.update(type='short_text', presentation={'control': 'input'}, maxLength=20)
            rehash(package)
            package_path, manifest_path = self.write_pair(directory, package)
            self.assertEqual(load_participant_package(package_path, manifest_path)['content']['fields'][1]
                             ['presentation']['control'], 'input')

    def test_rejects_a_manifest_that_changes_the_identity_tuple(self):
        with tempfile.TemporaryDirectory() as directory:
            package_path, manifest_path = self.write_pair(directory, package_fixture())
            manifest = json.loads(manifest_path.read_text())
            manifest['identity']['contentVersion'] = 'different'
            manifest_path.write_text(json.dumps(manifest))
            with self.assertRaisesRegex(ValueError, 'identity'):
                load_participant_package(package_path, manifest_path)

    def test_rejects_boolean_schema_and_identity_versions(self):
        for target, key in [('manifest', 'manifestSchemaVersion'), ('identity', 'identityVersion'),
                            ('identity', 'canonicalisationVersion')]:
            with self.subTest(target=target, key=key), tempfile.TemporaryDirectory() as directory:
                package = package_fixture()
                package_path, manifest_path = self.write_pair(directory, package)
                if target == 'manifest':
                    manifest = json.loads(manifest_path.read_text())
                    manifest[key] = True
                    manifest_path.write_text(json.dumps(manifest))
                else:
                    package['identity'][key] = True
                    rehash(package)
                    package_path, manifest_path = self.write_pair(directory, package)
                with self.assertRaises(ValueError):
                    load_participant_package(package_path, manifest_path)

    def test_rejects_duplicate_json_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            package_path, manifest_path = self.write_pair(directory, package_fixture())
            manifest_path.write_text('{"manifestSchemaVersion":1,"manifestSchemaVersion":1}')
            with self.assertRaisesRegex(ValueError, 'Duplicate'):
                load_participant_package(package_path, manifest_path)
