"""Verify private researcher packs supplied to the private export operation.

A researcher pack is read from a frozen instrument release directory produced by the thesis
instrument compiler. The application never packages, loads at startup, or serves these files.
"""
import hashlib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .content import (
    ContentSnapshot,
    canonical_identity,
    content_snapshot,
    load_participant_package,
    strict_json_loads,
)
from .service import ROOT

PACKAGE_FILE = 'participant-package-v2.json'
PUBLIC_MANIFEST_FILE = 'public-manifest.json'
RESEARCHER_PACK_FILE = 'researcher-pack.json'
RESEARCHER_MANIFEST_FILE = 'researcher-manifest.json'
PACK_KEYS = frozenset({'researcherSchemaVersion', 'publicIdentity', 'material', 'codebook', 'identity'})


class ResearcherPackError(ValueError):
    """A supplied researcher pack does not verify. Messages name the failed check, never pack content."""


@dataclass(frozen=True)
class ResearcherPack:
    """A verified researcher pack and the exact public snapshot its provenance declares."""
    snapshot: ContentSnapshot
    identity: dict[str, Any]
    public_identity: dict[str, Any]
    freeze_identity: dict[str, Any]
    schema_version: int
    material: dict[str, Any]
    codebook: dict[str, Any]


def load_researcher_pack(directory):
    """Verify one frozen release's researcher pack against its declared public and researcher provenance."""
    directory = Path(directory).resolve()
    if directory.is_relative_to(ROOT):
        raise ResearcherPackError('researcher packs must be kept outside the application repository')
    try:
        manifest = strict_json_loads((directory / RESEARCHER_MANIFEST_FILE).read_bytes())
        files = {name: (directory / name).read_bytes()
                 for name in (PACKAGE_FILE, PUBLIC_MANIFEST_FILE, RESEARCHER_PACK_FILE)}
    except OSError:
        raise ResearcherPackError('the release directory or one of its manifest/pack files is missing') from None
    except ValueError:
        raise ResearcherPackError('the researcher manifest is not strict JSON') from None
    declared = manifest.get('artifacts') if isinstance(manifest, dict) else None
    if (not isinstance(manifest, dict) or type(manifest.get('manifestSchemaVersion')) is not int
            or manifest['manifestSchemaVersion'] != 1 or not isinstance(declared, dict)):
        raise ResearcherPackError('unsupported researcher manifest')
    for name, data in files.items():
        if declared.get(name) != hashlib.sha256(data).hexdigest():
            raise ResearcherPackError(f'{name} bytes do not match the researcher manifest')
    try:
        package = load_participant_package(directory / PACKAGE_FILE, directory / PUBLIC_MANIFEST_FILE)
        snapshot = content_snapshot(package)
    except (OSError, ValueError, TypeError, KeyError):
        raise ResearcherPackError('the public package does not match its declared public identity') from None
    try:
        pack = strict_json_loads(files[RESEARCHER_PACK_FILE])
    except ValueError:
        raise ResearcherPackError('the researcher pack is not strict JSON') from None
    public = package['identity']
    if not isinstance(pack, dict) or set(pack) != PACK_KEYS or type(pack['researcherSchemaVersion']) is not int \
            or pack['researcherSchemaVersion'] != 1:
        raise ResearcherPackError('unsupported researcher pack schema')
    if pack['identity'] != canonical_identity({key: value for key, value in pack.items() if key != 'identity'}):
        raise ResearcherPackError('the researcher pack does not match its canonical researcher identity')
    researcher = manifest.get('researcher')
    public_record = manifest.get('public')
    if (not isinstance(researcher, dict) or researcher.get('identity') != pack['identity']
            or researcher.get('schemaVersion') != pack['researcherSchemaVersion']):
        raise ResearcherPackError('the researcher manifest declares a different researcher identity')
    codebook, material = pack['codebook'], pack['material']
    if (pack['publicIdentity'] != public or researcher.get('publicIdentity') != public
            or not isinstance(public_record, dict) or public_record.get('identity') != public
            or not isinstance(codebook, dict) or codebook.get('publicIdentity') != public):
        raise ResearcherPackError('the researcher pack is linked to a different public identity')
    freeze = manifest.get('freezeIdentity')
    if freeze != canonical_identity({'publicIdentity': public, 'researcherIdentity': pack['identity']}):
        raise ResearcherPackError('the release freeze identity does not bind its public and researcher identities')
    if not isinstance(material, dict):
        raise ResearcherPackError('unsupported researcher material')
    return ResearcherPack(snapshot, pack['identity'], public, freeze, pack['researcherSchemaVersion'],
                          material, codebook)


def join_researcher_packs(directories, snapshots):
    """Verify each supplied pack and key it by the exported snapshot digest its provenance declares.

    `snapshots` maps each exported snapshot digest to its stored ContentSnapshot. A pack must name
    exactly one of those snapshots, byte for byte, and no snapshot may receive two packs.
    """
    joined = {}
    for position, directory in enumerate(directories, start=1):
        try:
            pack = load_researcher_pack(directory)
        except ResearcherPackError as error:
            raise ResearcherPackError(f'pack {position}: {error}') from None
        digest = pack.snapshot.digest
        if snapshots.get(digest) != pack.snapshot:
            raise ResearcherPackError(f'pack {position}: public content {digest} is not referenced by any exported '
                                      'record')
        if digest in joined:
            raise ResearcherPackError(f'pack {position}: another pack is already joined to public content {digest}')
        joined[digest] = pack
    return joined
