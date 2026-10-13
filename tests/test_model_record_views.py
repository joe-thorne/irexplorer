"""The query views answer from model records resolved before they are called."""

import unittest
from dataclasses import replace

from src.backend.analysis.compare import compare_timeline_step
from src.backend.api import QueryError, QueryService
from src.backend.api.query import (
    ModelRecords,
    cfg_view,
    comparison_report_view,
    ir_view,
    source_mappings_view,
    source_view,
    states_view,
)
from src.backend.ingest import load_curated_source_record, load_curated_timeline

UNCURATED_ID = "f" * 64


def _records_outside_the_curated_resolver() -> ModelRecords:
    """Derive score's records in memory under an id the curated resolver does not know."""

    timeline = replace(load_curated_timeline("score"), example_id=UNCURATED_ID)
    return ModelRecords(
        timeline_id=UNCURATED_ID,
        timeline=timeline,
        correspondences=tuple(
            compare_timeline_step(timeline, ordinal) for ordinal in range(len(timeline.steps))
        ),
        source=load_curated_source_record("score"),
    )


class ModelRecordViewsTests(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls) -> None:
        cls.records = _records_outside_the_curated_resolver()
        cls.curated = QueryService(preload=False)

    def test_views_answer_as_the_curated_api_does_for_the_same_records(self) -> None:
        records, curated = self.records, self.curated

        self.assertEqual(states_view(records), curated.list_states("score"))
        self.assertEqual(source_view(records), {**curated.source("score"), "exampleId": UNCURATED_ID})
        for ordinal in (0, 4, 13):
            with self.subTest(ordinal=ordinal):
                self.assertEqual(ir_view(records, ordinal), curated.ir("score", ordinal))
                self.assertEqual(cfg_view(records, ordinal, "fn0"), curated.cfg("score", ordinal, "fn0"))
                self.assertEqual(
                    source_mappings_view(records, ordinal, "fn0"),
                    {**curated.source_mappings("score", ordinal, "fn0"), "exampleId": UNCURATED_ID},
                )
        self.assertEqual(
            comparison_report_view(records, 13, 0),
            {**curated.comparison_report("score", 0, 13), "exampleId": UNCURATED_ID},
        )

    def test_views_refuse_states_and_functions_the_records_lack(self) -> None:
        with self.assertRaises(QueryError):
            ir_view(self.records, 14)
        with self.assertRaises(QueryError):
            cfg_view(self.records, 0, "missing")
        with self.assertRaises(QueryError):
            comparison_report_view(self.records, 0, 14)

    def test_the_curated_service_resolves_only_curated_examples(self) -> None:
        with self.assertRaises(QueryError):
            self.curated.list_states(UNCURATED_ID)


if __name__ == "__main__":
    unittest.main()
