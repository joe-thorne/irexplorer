"""Parse textual LLVM IR into validated StateGraph records."""

from __future__ import annotations

from dataclasses import dataclass
import re

from src.backend.model.graph import (
    Edge,
    ModelValidationError,
    Node,
    Remark,
    SourceLocation,
    StateGraph,
)


class IngestError(ValueError):
    """Raised when LLVM artefacts cannot be ingested into the model."""


_SOURCE_RE = re.compile(r'^source_filename = "(.+)"$')
_TRIPLE_RE = re.compile(r'^target triple = "(.+)"$')
_DATALAYOUT_RE = re.compile(r'^target datalayout = "(.+)"$')
_DEFINE_RE = re.compile(r"^define\b.*@(?P<name>[-A-Za-z0-9_.$]+)\((?P<args>.*)\).*\{\s*$")
_BLOCK_RE = re.compile(r"^(?P<label>[-A-Za-z0-9_.$]+):(?:\s*;.*)?$")
_DBG_REF_RE = re.compile(r"!dbg !(\d+)")
_DILOC_RE = re.compile(r"^!(?P<id>\d+) = .*DILocation\(line: (?P<line>\d+), column: (?P<column>\d+),")
_VALUE_RE = re.compile(r"%[-A-Za-z0-9_.$]+")
_LABEL_REF_RE = re.compile(r"label\s+%([-A-Za-z0-9_.$]+)")
_PHI_INCOMING_RE = re.compile(r"\[[^\]]+,\s*%([-A-Za-z0-9_.$]+)\s*\]")


@dataclass
class _FunctionBuild:
    id: str
    name: str
    args: tuple[str, ...]
    header: str
    blocks: list["_BlockBuild"]


@dataclass
class _BlockBuild:
    id: str
    label: str
    instructions: list["_InstructionBuild"]


@dataclass
class _InstructionBuild:
    id: str
    text: str
    result: str | None
    opcode: str
    operands: tuple[str, ...]
    debug_ref: str | None
    source: SourceLocation | None
    incoming_blocks: tuple[str, ...]
    is_terminator: bool
    successors: tuple[tuple[str, str], ...]


def parse_ir_state(
    ir_text: str,
    *,
    ordinal: int,
    state_id: str,
    origin_command: str | None = None,
    remarks_text: str | None = None,
    opt_yaml_text: str | None = None,
) -> StateGraph:
    """Parse one LLVM IR state and validate the resulting graph."""

    try:
        graph = _parse_ir_state(
            ir_text,
            ordinal=ordinal,
            state_id=state_id,
            origin_command=origin_command,
            remarks_text=remarks_text,
            opt_yaml_text=opt_yaml_text,
        )
        graph.validate()
    except ModelValidationError as exc:
        raise IngestError(str(exc)) from exc
    return graph


def _parse_ir_state(
    ir_text: str,
    *,
    ordinal: int,
    state_id: str,
    origin_command: str | None,
    remarks_text: str | None,
    opt_yaml_text: str | None,
) -> StateGraph:
    lines = ir_text.splitlines()
    source_filename = _parse_single(lines, _SOURCE_RE)
    debug_locations = _parse_debug_locations(lines, source_filename or "")
    target_triple = _parse_single(lines, _TRIPLE_RE)
    target_datalayout = _parse_single(lines, _DATALAYOUT_RE)

    functions = _parse_functions(lines, debug_locations)
    if not functions:
        raise IngestError("IR contains no function definitions")

    remarks = _parse_remarks(opt_yaml_text or remarks_text or "")
    remark_lookup = _remarks_by_function_location(remarks)

    nodes: list[Node] = [
        Node(
            stable_id="module",
            kind="Module",
            display_name=source_filename or "<module>",
            attributes={
                "source_filename": source_filename,
                "target_triple": target_triple,
                "target_datalayout": target_datalayout,
            },
        )
    ]
    edges: list[Edge] = []
    block_id_by_function_label = {
        function.id: {block.label: block.id for block in function.blocks}
        for function in functions
    }

    for function_order, function in enumerate(functions):
        nodes.append(
            Node(
                stable_id=function.id,
                kind="Function",
                display_name=function.name,
                attributes={
                    "name": function.name,
                    "arguments": function.args,
                    "signature": function.header,
                },
            )
        )
        edges.append(Edge("module", function.id, "contains", order=function_order))

        for block_order, block in enumerate(function.blocks):
            nodes.append(
                Node(
                    stable_id=block.id,
                    kind="BasicBlock",
                    display_name=block.label,
                    attributes={"label": block.label},
                )
            )
            edges.append(Edge(function.id, block.id, "contains", order=block_order))

            for instruction_order, instruction in enumerate(block.instructions):
                instruction_remarks = _remarks_for_instruction(
                    remark_lookup,
                    function.name,
                    instruction.source,
                )
                attrs = {
                    "text": instruction.text,
                    "result": instruction.result,
                    "opcode": instruction.opcode,
                    "operands": instruction.operands,
                    "debug_ref": instruction.debug_ref,
                    "source": instruction.source,
                    "incoming_blocks": instruction.incoming_blocks,
                    "is_terminator": instruction.is_terminator,
                    "successors": tuple(
                        (block_id_by_function_label[function.id][label], edge_label)
                        for label, edge_label in instruction.successors
                    ),
                    "remarks": instruction_remarks,
                }
                nodes.append(
                    Node(
                        stable_id=instruction.id,
                        kind="Instruction",
                        display_name=instruction.result or instruction.opcode,
                        attributes=attrs,
                    )
                )
                edges.append(Edge(block.id, instruction.id, "contains", order=instruction_order))
                if instruction.source is not None:
                    edges.append(
                        Edge(
                            instruction.id,
                            _source_id(instruction.source),
                            "sourceMap",
                            label="debugLoc",
                        )
                    )

            for instruction in block.instructions:
                if not instruction.is_terminator:
                    continue
                for label, edge_label in instruction.successors:
                    try:
                        target_id = block_id_by_function_label[function.id][label]
                    except KeyError as exc:
                        raise IngestError(
                            f"terminator in {function.name}.{block.label} targets unknown block {label}"
                        ) from exc
                    edges.append(Edge(block.id, target_id, "controlFlow", label=edge_label))

    graph = StateGraph(
        ordinal=ordinal,
        state_id=state_id,
        nodes=tuple(nodes),
        edges=tuple(edges),
        source_filename=source_filename,
        target_triple=target_triple,
        target_datalayout=target_datalayout,
        origin_command=origin_command,
        remarks=remarks,
    )
    return graph


def _parse_single(lines: list[str], pattern: re.Pattern[str]) -> str | None:
    for line in lines:
        match = pattern.match(line)
        if match:
            return match.group(1)
    return None


def _parse_debug_locations(lines: list[str], source_filename: str) -> dict[str, SourceLocation]:
    locations: dict[str, SourceLocation] = {}
    for line in lines:
        match = _DILOC_RE.match(line)
        if not match:
            continue
        locations[match.group("id")] = SourceLocation(
            file=source_filename,
            line=int(match.group("line")),
            column=int(match.group("column")),
        )
    return locations


def _parse_functions(
    lines: list[str],
    debug_locations: dict[str, SourceLocation],
) -> list[_FunctionBuild]:
    functions: list[_FunctionBuild] = []
    current_function: _FunctionBuild | None = None
    current_block: _BlockBuild | None = None

    for line_no, line in enumerate(lines, start=1):
        define = _DEFINE_RE.match(line)
        if define:
            if current_function is not None:
                raise IngestError(f"nested function definition at line {line_no}")
            function_id = f"fn{len(functions)}"
            current_function = _FunctionBuild(
                id=function_id,
                name=define.group("name"),
                args=_parse_arguments(define.group("args")),
                header=line,
                blocks=[],
            )
            current_block = None
            continue

        if current_function is None:
            continue

        if line == "}":
            if current_block is not None:
                _require_terminated(current_function, current_block)
            if not current_function.blocks:
                raise IngestError(f"function {current_function.name} has no basic blocks")
            functions.append(current_function)
            current_function = None
            current_block = None
            continue

        block_match = _BLOCK_RE.match(line)
        if block_match:
            if current_block is not None:
                _require_terminated(current_function, current_block)
            block_id = f"{current_function.id}/bb{len(current_function.blocks)}"
            current_block = _BlockBuild(
                id=block_id,
                label=block_match.group("label"),
                instructions=[],
            )
            current_function.blocks.append(current_block)
            continue

        stripped = line.strip()
        if not stripped or stripped.startswith(";") or stripped.startswith("#dbg_"):
            continue
        if current_block is None:
            raise IngestError(
                f"instruction before first basic block in function {current_function.name} at line {line_no}"
            )

        instruction = _parse_instruction(
            stripped,
            instruction_id=f"{current_block.id}/i{len(current_block.instructions)}",
            debug_locations=debug_locations,
        )
        current_block.instructions.append(instruction)

    if current_function is not None:
        raise IngestError(f"unterminated function definition: {current_function.name}")
    return functions


def _require_terminated(function: _FunctionBuild, block: _BlockBuild) -> None:
    if not block.instructions:
        raise IngestError(f"empty basic block: {function.name}.{block.label}")
    if not block.instructions[-1].is_terminator:
        raise IngestError(f"basic block lacks terminator: {function.name}.{block.label}")


def _parse_arguments(args: str) -> tuple[str, ...]:
    values = []
    for arg in _split_top_level_commas(args):
        matches = _VALUE_RE.findall(arg)
        if matches:
            values.append(matches[-1])
    return tuple(values)


def _parse_instruction(
    text: str,
    *,
    instruction_id: str,
    debug_locations: dict[str, SourceLocation],
) -> _InstructionBuild:
    result: str | None = None
    body = text
    assign = re.match(r"^(%[-A-Za-z0-9_.$]+)\s*=\s*(.+)$", text)
    if assign:
        result = assign.group(1)
        body = assign.group(2)

    opcode = _normalise_opcode(body)
    debug_ref = _debug_ref(text)
    source = debug_locations.get(debug_ref) if debug_ref else None
    successors = _successors(body)
    # Terminators recognised for the curated C set. Other LLVM terminators
    # (invoke, callbr, indirectbr, catchswitch, catchret, cleanupret) do not
    # appear in these examples; if one ever ends a block it is left unrecognised
    # and ingestion fails in a controlled way via _require_terminated (FR15/NFR8),
    # never silently mislabelled. Full terminator support is scheduled with
    # user-supplied / C++ input (implementation-plan S2.6 / Phase 4).
    is_terminator = opcode in {"br", "ret", "switch", "unreachable", "resume"}

    return _InstructionBuild(
        id=instruction_id,
        text=text,
        result=result,
        opcode=opcode,
        operands=tuple(_VALUE_RE.findall(body)),
        debug_ref=debug_ref,
        source=source,
        incoming_blocks=tuple(_PHI_INCOMING_RE.findall(body)) if opcode == "phi" else (),
        is_terminator=is_terminator,
        successors=successors,
    )


def _normalise_opcode(body: str) -> str:
    words = body.split(None, 2)
    if not words:
        raise IngestError("empty instruction")
    if len(words) >= 2 and words[0] in {"tail", "musttail", "notail"} and words[1] == "call":
        return "call"
    return words[0]


def _debug_ref(text: str) -> str | None:
    match = _DBG_REF_RE.search(text)
    return match.group(1) if match else None


def _successors(body: str) -> tuple[tuple[str, str], ...]:
    if body.startswith("br label "):
        labels = _LABEL_REF_RE.findall(body)
        return ((labels[0], "unconditional"),) if labels else ()
    if body.startswith("br "):
        labels = _LABEL_REF_RE.findall(body)
        if len(labels) != 2:
            raise IngestError(f"conditional branch has {len(labels)} labels: {body}")
        return ((labels[0], "true"), (labels[1], "false"))
    if body.startswith("switch "):
        labels = _LABEL_REF_RE.findall(body)
        if not labels:
            raise IngestError(f"switch has no labels: {body}")
        edges = [(labels[0], "default")]
        edges.extend((label, f"switch-case({index})") for index, label in enumerate(labels[1:]))
        return tuple(edges)
    return ()


def _split_top_level_commas(text: str) -> tuple[str, ...]:
    parts: list[str] = []
    start = 0
    depth = 0
    for index, char in enumerate(text):
        if char in "([{<":
            depth += 1
        elif char in ")]}>":
            depth = max(0, depth - 1)
        elif char == "," and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return tuple(parts)


def _parse_remarks(text: str) -> tuple[Remark, ...]:
    records = [record.strip() for record in text.split("---") if record.strip()]
    remarks: list[Remark] = []
    for record in records:
        if record.endswith("..."):
            record = record[:-3].rstrip()
        pass_name = _record_scalar(record, "Pass") or ""
        name = _record_scalar(record, "Name") or ""
        function = _record_scalar(record, "Function") or ""
        location = _record_location(record)
        if pass_name or name or function or location:
            remarks.append(
                Remark(
                    pass_name=pass_name,
                    name=name,
                    function=function,
                    location=location,
                    raw=record,
                )
            )
    return tuple(remarks)


def _record_scalar(record: str, key: str) -> str | None:
    match = re.search(rf"^({re.escape(key)}):\s*(.+?)\s*$", record, flags=re.MULTILINE)
    if not match:
        return None
    return match.group(2).strip().strip("'\"")


def _record_location(record: str) -> SourceLocation | None:
    match = re.search(
        r"DebugLoc:\s*\{\s*File:\s*'?(?P<file>[^,']+)'?,\s*Line:\s*(?P<line>\d+),\s*Column:\s*(?P<column>\d+)\s*\}",
        record,
    )
    if not match:
        return None
    return SourceLocation(
        file=match.group("file"),
        line=int(match.group("line")),
        column=int(match.group("column")),
    )


def _remarks_by_function_location(
    remarks: tuple[Remark, ...],
) -> dict[tuple[str, int, int], tuple[Remark, ...]]:
    grouped: dict[tuple[str, int, int], list[Remark]] = {}
    for remark in remarks:
        if remark.location is None:
            continue
        grouped.setdefault(
            (remark.function, remark.location.line, remark.location.column),
            [],
        ).append(remark)
    return {key: tuple(value) for key, value in grouped.items()}


def _remarks_for_instruction(
    remark_lookup: dict[tuple[str, int, int], tuple[Remark, ...]],
    function: str,
    source: SourceLocation | None,
) -> tuple[Remark, ...]:
    if source is None:
        return ()
    exact = remark_lookup.get((function, source.line, source.column), ())
    line_level = remark_lookup.get((function, source.line, 0), ())
    return exact + tuple(remark for remark in line_level if remark not in exact)


def _source_id(location: SourceLocation) -> str:
    return f"source:{location.file}:{location.line}:{location.column}"
