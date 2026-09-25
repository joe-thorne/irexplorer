"""Pin comparison reports to the reviewed pre-rename response digests.

Regenerate only after a deliberate, reviewed change to summary behaviour:

    .venv/bin/python -m tests.test_summary_digests --write
    .venv/bin/python -m tests.test_summary_digests --dump DIR   # full responses, for diffing
"""

import argparse
import json
import unittest
from hashlib import sha256
from pathlib import Path

from src.backend.api import QueryService

FIXTURE = Path(__file__).parent / "data" / "summary-digests.sha256"
HEADER = (
    "# SHA-256 of each comparison report normalised to the former summary response keys,\n"
    "# serialised as compact JSON in response key order. This preserves response-level\n"
    "# rename equivalence. Update only after a deliberate, reviewed report change:\n"
    "# python -m tests.test_summary_digests --write\n"
    "# The v3 re-pin followed exact comparison of 315 response payloads and 45\n"
    "# model records under the declared rename mapping; see\n"
    "# docs/model-record-v3-migration.md.\n"
)


def comparison_report_responses(service: QueryService):
    """Yield (span name, response) for every lower<=higher span of every example."""
    for example in service.list_examples()["examples"]:
        count = len(service.list_states(example)["states"])
        for lower in range(count):
            for higher in range(lower, count):
                yield f"{example} {lower:02d}-{higher:02d}", service.comparison_report(example, lower, higher)


def normalise_report_renames(response):
    """Restore the prior wire keys so unchanged report content retains its digest."""
    def rename_fields(record, names):
        return {names.get(key, key): value for key, value in record.items()}

    return {
        key: (
            [rename_fields(state, {"step": "transition"}) for state in value]
            if key == "states"
            else value
        )
        for key, value in rename_fields(response, {"structuralClaims": "items"}).items()
    }


def canonical(response) -> str:
    return json.dumps(response, ensure_ascii=False, separators=(",", ":"))


def comparison_report_digests(service: QueryService) -> dict[str, str]:
    return {span: sha256(canonical(normalise_report_renames(response)).encode("utf-8")).hexdigest()
            for span, response in comparison_report_responses(service)}


def read_fixture() -> dict[str, str]:
    digests = {}
    for line in FIXTURE.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            digest, span = line.split("  ", 1)
            digests[span] = digest
    return digests


class SummaryDigestTests(unittest.TestCase):
    def test_every_comparison_report_matches_its_reviewed_digest(self) -> None:
        """Expose any change to participant-visible report output, span by span."""
        actual = comparison_report_digests(QueryService())
        expected = read_fixture()
        self.assertEqual(sorted(actual), sorted(expected), "summary span set changed")
        changed = sorted(span for span in expected if actual[span] != expected[span])
        self.assertEqual(changed, [], "summary responses changed; dump them with --dump to review")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true", help="rewrite the reviewed digest fixture")
    group.add_argument("--dump", type=Path, metavar="DIR", help="write each full response as JSON")
    args = parser.parse_args()
    service = QueryService()
    if args.write:
        lines = [f"{digest}  {span}" for span, digest in comparison_report_digests(service).items()]
        FIXTURE.write_text(HEADER + "\n".join(lines) + "\n", encoding="utf-8")
        print(f"wrote {len(lines)} digests to {FIXTURE}")
    else:
        args.dump.mkdir(parents=True, exist_ok=True)
        for span, response in comparison_report_responses(service):
            name = span.replace(" ", "_") + ".json"
            (args.dump / name).write_text(json.dumps(response, ensure_ascii=False, indent=2) + "\n",
                                          encoding="utf-8")
        print(f"wrote responses to {args.dump}")


if __name__ == "__main__":
    main()
