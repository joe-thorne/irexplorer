"""The user programs setting: read once at startup, off by default, refused in every unsafe combination."""
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient

from src.backend.api.app import create_app
from src.backend.evaluation.service import Config

COMPILER_URL = 'http://127.0.0.1:9'
ON = {'IREXPLORER_USER_PROGRAMS': '1', 'IREXPLORER_COMPILER_URL': COMPILER_URL}


def packaged_research_config(directory, mode):
    """Pilot or live collection that passes every study guard, as a packaged release (not this checkout)."""
    with patch('src.backend.evaluation.service.metadata',
               lambda: {'version': '0.6.0', 'revision': '0.6.0+packaged'}):
        return Config(Path(directory), collection_mode=mode, origin='https://study.example.test',
                      app_revision='0.6.0+packaged')


class UserProgramsSettingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.study = {'IREXPLORER_STUDY_DIR': self.tmp.name}

    def start(self, study_config=None, **settings):
        """Create the app as startup does, from exactly these environment settings."""
        with patch.dict('os.environ', {**self.study, **settings}, clear=True):
            return TestClient(create_app(study_config=study_config))

    def test_release_reports_the_setting_beside_the_unchanged_identity(self):
        for settings, enabled in (({}, False),
                                  ({'IREXPLORER_USER_PROGRAMS': '0'}, False),
                                  (ON, True)):
            with self.subTest(settings=settings):
                release = self.start(**settings).get('/api/release')
                self.assertEqual(release.status_code, 200)
                self.assertEqual(release.headers['cache-control'], 'no-store')
                self.assertEqual(release.json(), {'version': 'development', 'revision': 'development',
                                                  'config': {'userPrograms': enabled}})

    def test_any_other_value_stops_startup(self):
        for value in ('', 'true', 'True', 'yes', 'on', '01', ' 1', '1 ', '2', '-1'):
            with (self.subTest(value=value),
                  self.assertRaisesRegex(ValueError, 'IREXPLORER_USER_PROGRAMS must be 0 .* or 1')):
                self.start(IREXPLORER_USER_PROGRAMS=value, IREXPLORER_COMPILER_URL=COMPILER_URL)

    def test_turning_user_programs_on_needs_a_compiler_address(self):
        for settings in ({}, {'IREXPLORER_COMPILER_URL': ''}):
            with (self.subTest(settings=settings),
                  self.assertRaisesRegex(ValueError, 'IREXPLORER_USER_PROGRAMS=1 requires IREXPLORER_COMPILER_URL')):
                self.start(IREXPLORER_USER_PROGRAMS='1', **settings)

    def test_a_compiler_address_alone_never_turns_user_programs_on(self):
        for settings in ({}, {'IREXPLORER_USER_PROGRAMS': '0'}):
            with self.subTest(settings=settings):
                client = self.start(IREXPLORER_COMPILER_URL=COMPILER_URL, **settings)
                self.assertEqual(client.get('/api/release').json()['config'], {'userPrograms': False})

    def test_with_the_setting_off_programs_routes_are_not_mounted(self):
        # An unmounted route answers exactly as a path that was never routed: a plain 404 not_found for
        # a read (never unknown_program), and the static frontend's refusal of any other method.
        program_id = 'a' * 64
        paths = ('/api/programs', f'/api/programs/{program_id}', f'/api/programs/{program_id}/states',
                 f'/api/programs/{program_id}/source', f'/api/programs/{program_id}/states/0/ir',
                 f'/api/programs/{program_id}/states/0/cfg?functionId=main',
                 f'/api/programs/{program_id}/states/0/source-mappings?functionId=main',
                 f'/api/programs/{program_id}/comparison-report?fromOrdinal=0&toOrdinal=1')
        for settings in ({}, {'IREXPLORER_USER_PROGRAMS': '0', 'IREXPLORER_COMPILER_URL': COMPILER_URL}):
            client = self.start(**settings)
            for path in paths:
                with self.subTest(settings=settings, path=path):
                    response = client.get(path)
                    self.assertEqual((response.status_code, response.json()['error']['code']), (404, 'not_found'))
            never_routed = client.post('/api/never-routed', json={})
            posted = client.post('/api/programs', json={'fileName': 'main.c', 'source': 'int main(void) {}\n'})
            self.assertEqual((posted.status_code, posted.json()), (never_routed.status_code, never_routed.json()))

    def test_user_programs_never_run_beside_research_collection(self):
        for mode in ('pilot', 'live'):
            config = packaged_research_config(self.tmp.name, mode)
            with self.subTest(mode=mode, setting='0'):
                self.assertEqual(self.start(config).get('/api/release').json()['config'], {'userPrograms': False})
            with (self.subTest(mode=mode, setting='1'),
                  self.assertRaisesRegex(ValueError, f'User programs cannot run with {mode} collection')):
                self.start(config, **ON)
        # Local and preview collection never hold research data, so the feature may run beside them.
        for mode in ('local', 'preview'):
            with self.subTest(mode=mode):
                client = self.start(Config(Path(self.tmp.name), collection_mode=mode), **ON)
                self.assertEqual(client.get('/api/release').json()['config'], {'userPrograms': True})


if __name__ == '__main__':
    unittest.main()
