"""Layer 2 ingestion boundary."""

from src.backend.ingest.curated import (
    SourceRecord,
    bake_curated_model_records,
    load_curated_source_record,
    load_curated_timeline,
    load_curated_timeline_record,
)
from src.backend.ingest.llvm_ir import IngestError, NoFunctionDefinitions, UnsupportedTerminator, parse_ir_state
from src.backend.ingest.timeline import StateArtefacts, build_timeline

__all__ = [
    "IngestError",
    "NoFunctionDefinitions",
    "SourceRecord",
    "StateArtefacts",
    "UnsupportedTerminator",
    "bake_curated_model_records",
    "build_timeline",
    "load_curated_timeline",
    "load_curated_source_record",
    "load_curated_timeline_record",
    "parse_ir_state",
]
