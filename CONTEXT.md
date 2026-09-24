# irexplorer

A web application that shows how LLVM optimisation passes transform a program's intermediate representation across a recorded sequence of compiler states.

## Language

### Timeline

**Optimisation timeline**:
The ordered sequence of recorded compiler states for one program, joined by the steps between them.
_Avoid_: pipeline, history

**State**:
One recorded LLVM IR snapshot of the program, identified by its ordinal in the timeline.
_Avoid_: stage, version

**Step**:
The transition between two adjacent states, carrying the pass that produced it and any compiler remarks it emitted.
_Avoid_: transition, pass run

**Span**:
A from→to pair of states in one timeline, always read from the lower ordinal to the higher; adjacent or not.
_Avoid_: range, diff

### Comparison

**Correspondence**:
The set of links relating IR elements in one state to IR elements in another, each with a relation and a confidence tier.
_Avoid_: mapping, overlay (except for the baked per-step file)

**Compiler remark**:
A message the compiler emitted during a step; evidence about what a pass did, not a complete explanation of its intent.
_Avoid_: diagnostic, log

**Comparison report**:
Everything the application can truthfully say about one span of a timeline: its states, steps, correspondence links, summary items, compiler remarks, and detected optimisations.
_Avoid_: summary (reserved for the report's summary items), diff
