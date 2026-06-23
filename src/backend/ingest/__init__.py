"""Layer 2 ingestion boundary."""

from src.backend.ingest.llvm_ir import IngestError, parse_ir_state

__all__ = ["IngestError", "parse_ir_state"]
