# irexplorer

A web application that shows how LLVM optimisation passes transform a program's intermediate representation across a recorded sequence of compiler states.

## Language

### Artefacts

**Curated example**:
One of the small, fixed C programs the application ships with, chosen to exhibit particular optimisations.
_Avoid_: sample, test program, user program

**Pinned toolchain**:
The exact LLVM version and container environment in which all compiler artefacts are produced, so they can be regenerated identically.
_Avoid_: environment pin, toolchain pin

**Compiler artefacts**:
The raw IR, CFG, and remark output produced by the pinned toolchain for a curated example.
_Avoid_: golden fixtures, canonical fixtures, canonical artefacts

**Model records**:
The processed timelines and stored correspondences derived from compiler artefacts ahead of time; the only thing the running application reads.
_Avoid_: pre-baked records, baked data

### Timeline

**Optimisation timeline**:
The ordered sequence of recorded compiler states for one curated example, joined by the steps between them.
_Avoid_: pipeline, history

**State**:
One recorded LLVM IR snapshot of the program, identified by its ordinal in the timeline.
_Avoid_: stage, version, step (for a state or its ordinal)

**Unoptimised baseline**:
The first state, compiled without optimisation; every later state is read against it. "Baseline" alone is acceptable shorthand.
_Avoid_: O0 state (in student-facing text), starting state, original

**Ordinal**:
A state's zero-based position in its optimisation timeline; users see it as "State N".
_Avoid_: index, step number

**No-op state**:
A state recorded after a pass that made no change to the IR; kept in the timeline so the curated pass sequence stays complete.
_Avoid_: skipped state, empty state

**Step**:
The change between two adjacent states, carrying the pass that produced it and any compiler remarks it emitted.
_Avoid_: transition, pass run

**Curated pass sequence**:
The fixed, hand-chosen series of individual optimisation passes applied one at a time from the unoptimised state; a teaching approximation, not LLVM's real `-O3` pipeline.
_Avoid_: teaching pass chain, pipeline, O3 pipeline

**Recompiled O3 state**:
The final state, compiled independently from source at `-O3` rather than derived from the previous state, so its correspondence to earlier states is necessarily conservative.
_Avoid_: anchor, recompiled anchor, O3 pass

**Span**:
A from→to pair of states in one timeline, always read from the lower ordinal to the higher; adjacent or not.
_Avoid_: range, diff

### Comparison

**Correspondence**:
The set of links relating IR elements in one state to IR elements in another, accounting for every function, basic block, and instruction on both sides.
_Avoid_: mapping, overlay

**Stored correspondence**:
A correspondence for one step, produced ahead of time from the compiler artefacts.
_Avoid_: overlay, baked overlay

**Composed correspondence**:
A correspondence for a non-adjacent span, chained from stored correspondences on request and never kept; it can only be as confident as its weakest link in the chain.
_Avoid_: overlay, derived mapping

**Link**:
One entry in a correspondence joining one or more elements in the earlier state to one or more in the later state, with a relation, a confidence tier, and optional evidence for why it was drawn.
_Avoid_: edge, hyperedge, match

**Relation**:
What a link says happened to its elements: same, renamed, moved, simplified into, promoted, split, merged, added, removed, or changed.
_Avoid_: change type, edit kind

**Confidence tier**:
How firmly a link is established: exact, approximate, plausible, or unresolved.
The stored value `unresolved` means no counterpart could be established.
_Avoid_: certainty, score, none

**Unresolved**:
The confidence tier of a link for which no counterpart could be established; the tool admits it does not know.
_Avoid_: unmatched, missing

**Compiler remark**:
A message the compiler emitted during a step; evidence about what a pass did, not a complete explanation of its intent.
_Avoid_: diagnostic, log

**Detected optimisation**:
A recognised transformation pattern, such as strength reduction or constant folding, found by inspecting a span, with its purpose, what changed, and a certainty.
_Avoid_: pass, remark, optimisation event

**Certainty**:
How firmly a detected optimisation is claimed: detected or likely. Distinct from a link's confidence tier.
_Avoid_: confidence

**Structural claim**:
One statement in a comparison report that is traceable to specific links and/or compiler remarks.
_Avoid_: summary item, report item, summary

**Comparison report**:
Everything the application can truthfully say about one span of a timeline: its states, steps, correspondence links, structural claims, compiler remarks, and detected optimisations.
_Avoid_: summary, diff

**Source mapping**:
The relationship between C source lines and IR instructions within a single state, taken from the compiler's debug information; separate from correspondence, which relates states to one another.
_Avoid_: correspondence, source correspondence

### Exploration

**Workspace**:
The comparison area holding two panels side by side.
_Avoid_: comparison view, split view

**Panel**:
One side of the workspace, independently set to a state and a view (IR text or CFG).
_Avoid_: pane

**Source selection**:
A range of C source lines the user has picked as the starting point for a trace.
_Avoid_: anchor

**Trace**:
What a selection of C lines, IR instructions, or a CFG block reaches when its links are followed across both panels; unresolved if any selected element lacks an established counterpart.
_Avoid_: highlight, counterparts, mapping

### Study

**Participant journey**:
The full in-application path a study participant takes, from information and consent to a confirmed submission.
_Avoid_: session, flow, study run

**Study section**:
One part of the participant journey: information, pre-survey, tasks, post-survey, or review.
_Avoid_: stage, phase, step

**Participant code**:
A random identifier generated for each participant; the only key on their response and the only way to request its withdrawal.
_Avoid_: participant ID, participant UUID, user ID

**Draft**:
A participant's unsubmitted answers, held only in their current browser tab and never sent to the server.
_Avoid_: saved progress, session

**Submission**:
A participant's final answers, frozen once with a submission ID so that any retry sends exactly the same content.
_Avoid_: envelope, payload, response upload

**Receipt**:
The server's confirmation that a submission has been durably stored; only after it is the draft discarded.
_Avoid_: acknowledgement, confirmation code

**Setup reached**:
Whether a participant got the comparison a task asks for on screen; a task without it is recorded as skipped or unable, not as answered incorrectly.
_Avoid_: task started, attempted

**Active duration**:
Time spent on a task after setup is reached, excluding hidden-tab time, explicit pauses, and reloads.
_Avoid_: task time, completion time

**Collection mode**:
Which body of responses a running application contributes to: local, preview, pilot, or live, each stored separately.
_Avoid_: study mode, environment

**Local collection**:
Collection on a researcher's own machine for development and checking; never research data.
_Avoid_: dev mode

**Preview collection**:
Synthetic end-to-end testing of the participant journey; never research data.
_Avoid_: legacy mode, demo mode

**Pilot collection**:
A small run with real participants before live collection, to confirm the journey works as intended.
_Avoid_: rehearsal, trial

**Live collection**:
Collection of research responses from recruited participants.
_Avoid_: production, real mode

### Release

**Release identity**:
The version, source fingerprint, and artefact checksum that identify exactly which build of the application is running; recorded with every submission.
_Avoid_: build number, revision (alone)
