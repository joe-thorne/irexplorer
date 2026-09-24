"""Layer 4 pure comparison and summary functions."""

from src.backend.analysis.compare import (
    ComparisonSummary,
    ComposedCorrespondence,
    SummaryItem,
    compare_states,
    compare_timeline_step,
    compose_correspondences,
    compose_timeline_correspondences,
    is_identity_correspondence,
)
from src.backend.analysis.curated import (
    bake_curated_comparison_records,
    load_prebaked_curated_correspondence,
    load_prebaked_curated_correspondences,
)

__all__ = [
    "ComparisonSummary",
    "ComposedCorrespondence",
    "SummaryItem",
    "compose_correspondences",
    "compose_timeline_correspondences",
    "compare_states",
    "compare_timeline_step",
    "is_identity_correspondence",
    "bake_curated_comparison_records",
    "load_prebaked_curated_correspondence",
    "load_prebaked_curated_correspondences",
]
