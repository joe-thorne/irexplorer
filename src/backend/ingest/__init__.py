"""Layer 2 ingestion boundary."""

from src.backend.ingest.curated import (
    SourceRecord,
    bake_curated_model_records,
    load_curated_source_record,
    load_curated_timeline,
    load_curated_timeline_record,
)
from src.backend.ingest.llvm_ir import IngestError, parse_ir_state

__all__ = [
    "IngestError",
    "SourceRecord",
    "bake_curated_model_records",
    "load_curated_timeline",
    "load_curated_source_record",
    "load_curated_timeline_record",
    "parse_ir_state",
]
