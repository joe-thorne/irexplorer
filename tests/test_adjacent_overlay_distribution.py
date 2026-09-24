import json
import unittest
from collections import Counter
from pathlib import Path

from src.backend.api import QueryService

FIXTURE = Path(__file__).parent / "data" / "adjacent-overlay-distribution.json"
RELATIONS = (
    "same",
    "removed",
    "changed",
    "added",
    "renamed",
    "simplifiedInto",
    "merged",
    "moved",
)


class AdjacentOverlayDistributionTests(unittest.TestCase):
    def test_adjacent_overlay_relation_confidence_distribution_matches_fixture(self) -> None:
        """Expose model drift across every adjacent overlay through QueryService."""
        service = QueryService()
        overlays = {}
        totals = Counter()

        for example in service.list_examples()["examples"]:
            states = service.list_states(example)["states"]
            pairs = {}
            for ordinal in range(len(states) - 1):
                links = service.summary(example, ordinal, ordinal + 1)["links"]
                pairs[f"{ordinal}-{ordinal + 1}"] = dict(sorted(
                    Counter(
                        f"{link['relation']}/{link['confidence']}"
                        for link in links
                    ).items()
                ))
                totals.update(link["relation"] for link in links)
            overlays[example] = pairs

        actual = {
            "summary": {
                "adjacentPairs": sum(len(pairs) for pairs in overlays.values()),
                "relationTotals": {relation: totals[relation] for relation in RELATIONS},
            },
            "overlays": overlays,
        }
        expected = json.loads(FIXTURE.read_text(encoding="utf-8"))
        self.assertEqual(actual, expected)
