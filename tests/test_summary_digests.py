"""Pin comparison reports and prove file-name response equivalence.

Regenerate only after a deliberate, reviewed change to summary behaviour:

    .venv/bin/python -m tests.test_summary_digests --write
    .venv/bin/python -m tests.test_summary_digests --dump DIR   # full responses, for diffing
"""

import argparse
import json
import re
import unittest
from hashlib import sha256
from pathlib import Path, PurePosixPath

from src.backend.api import QueryService

FIXTURE = Path(__file__).parent / "data" / "summary-digests.sha256"
PRE_FILE_NAME_FIXTURE = Path(__file__).parent / "data" / "summary-digests.pre-file-name.sha256"
HEADER = (
    "# SHA-256 of each comparison report normalised to the former summary response keys,\n"
    "# serialised as compact JSON in response key order. The pre-file-name response\n"
    "# digests are retained in summary-digests.pre-file-name.sha256; the test restores\n"
    "# every structured and raw remark path and proves equivalence to that baseline.\n"
    "# Update only after a deliberate, reviewed report change:\n"
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


def restore_pre_file_name_paths(value):
    """Map participant-facing file names back to the captured report path shape."""
    if isinstance(value, dict):
        for key, item in value.items():
            if key == "location" and isinstance(item, dict) and item.get("file"):
                item["file"] = f"examples/curated/{PurePosixPath(item['file']).name}"
            else:
                value[key] = restore_pre_file_name_paths(item)
        return value
    if isinstance(value, list):
        return [restore_pre_file_name_paths(item) for item in value]
    if isinstance(value, str):
        def restore(match: re.Match[str]) -> str:
            path = match.group("path").strip()
            if not path:
                return match.group(0)
            return (f"{match.group('prefix')}{match.group('quote')}"
                    f"examples/curated/{PurePosixPath(path).name}{match.group('quote')}")

        return re.sub(
            r"(?m)(?P<prefix>\bFile:\s*)(?P<quote>['\"]?)(?P<path>[^,'\"\r\n]+)(?P=quote)",
            restore,
            value,
        )
    return value


def read_fixture_from(path: Path) -> dict[str, str]:
    digests = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            digest, span = line.split("  ", 1)
            digests[span] = digest
    return digests


def read_fixture() -> dict[str, str]:
    return read_fixture_from(FIXTURE)


class SummaryDigestTests(unittest.TestCase):
    def test_every_comparison_report_matches_its_reviewed_digest(self) -> None:
        """Expose any change to participant-visible report output, span by span."""
        actual = comparison_report_digests(QueryService())
        expected = read_fixture()
        self.assertEqual(sorted(actual), sorted(expected), "summary span set changed")
        changed = sorted(span for span in expected if actual[span] != expected[span])
        self.assertEqual(changed, [], "summary responses changed; dump them with --dump to review")

    def test_every_response_restores_to_its_pre_file_name_digest(self) -> None:
        """Only the declared location and raw File path shape changes in all report spans."""
        expected = read_fixture_from(PRE_FILE_NAME_FIXTURE)
        actual = {
            span: sha256(canonical(normalise_report_renames(restore_pre_file_name_paths(response)))
                         .encode("utf-8")).hexdigest()
            for span, response in comparison_report_responses(QueryService())
        }
        self.assertEqual(sorted(actual), sorted(expected), "pre-change summary span set changed")
        changed = sorted(span for span in expected if actual[span] != expected[span])
        self.assertEqual(changed, [], "file-path-restored reports differ from the pre-change golden responses")


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
