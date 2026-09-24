"""Pin every curated summary response to a reviewed SHA-256 digest.

Regenerate only after a deliberate, reviewed change to summary behaviour:

    .venv/bin/python -m tests.test_summary_digests --write
    .venv/bin/python -m tests.test_summary_digests --dump DIR   # full responses, for diffing
"""

import argparse
import json
from hashlib import sha256
from pathlib import Path
import unittest

from src.backend.api import QueryService


FIXTURE = Path(__file__).parent / "data" / "summary-digests.sha256"
HEADER = (
    "# SHA-256 of each QueryService.summary response, serialised as compact JSON\n"
    "# in response key order. Update only after a deliberate, reviewed change to\n"
    "# summary behaviour: python -m tests.test_summary_digests --write\n"
)


def summary_responses(service: QueryService):
    """Yield (span name, response) for every lower<=higher span of every example."""
    for example in service.list_examples()["examples"]:
        count = len(service.list_states(example)["states"])
        for lower in range(count):
            for higher in range(lower, count):
                yield f"{example} {lower:02d}-{higher:02d}", service.summary(example, lower, higher)


def canonical(response) -> str:
    return json.dumps(response, ensure_ascii=False, separators=(",", ":"))


def summary_digests(service: QueryService) -> dict[str, str]:
    return {span: sha256(canonical(response).encode("utf-8")).hexdigest()
            for span, response in summary_responses(service)}


def read_fixture() -> dict[str, str]:
    digests = {}
    for line in FIXTURE.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            digest, span = line.split("  ", 1)
            digests[span] = digest
    return digests


class SummaryDigestTests(unittest.TestCase):
    def test_every_summary_response_matches_its_reviewed_digest(self) -> None:
        """Expose any change to participant-visible summary output, span by span."""
        actual = summary_digests(QueryService())
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
        lines = [f"{digest}  {span}" for span, digest in summary_digests(service).items()]
        FIXTURE.write_text(HEADER + "\n".join(lines) + "\n", encoding="utf-8")
        print(f"wrote {len(lines)} digests to {FIXTURE}")
    else:
        args.dump.mkdir(parents=True, exist_ok=True)
        for span, response in summary_responses(service):
            name = span.replace(" ", "_") + ".json"
            (args.dump / name).write_text(json.dumps(response, ensure_ascii=False, indent=2) + "\n",
                                          encoding="utf-8")
        print(f"wrote responses to {args.dump}")


if __name__ == "__main__":
    main()
