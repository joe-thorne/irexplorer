"""Layer 2 ingestion boundary."""

from src.backend.ingest.curated import (
    SourceRecord,
    bake_curated_model_records,
    load_curated_timeline,
    load_prebaked_curated_source,
    load_prebaked_curated_timeline,
)
from src.backend.ingest.llvm_ir import IngestError, parse_ir_state

__all__ = [
    "IngestError",
    "SourceRecord",
    "bake_curated_model_records",
    "load_curated_timeline",
    "load_prebaked_curated_source",
    "load_prebaked_curated_timeline",
    "parse_ir_state",
]
