# Curated learning tasks

## Purpose

The browser presents one short task at a time after the current pass story. A
task asks the learner to inspect existing source, IR, CFG, or correspondence
evidence before revealing a recorded observation. It does not add a compiler
claim or infer an effect from a pass name: the reveal is worded only from the
pre-baked model-query records listed below.

The **Open starting evidence** control opens the requested recorded state. For
source-led tasks it selects a mapped source line; for the `quick_sort` task it
opens the full-artefact navigation and selects the named function. The learner
then uses the normal timeline, source, IR, CFG, and evidence controls. This
keeps the walkthrough inside the presentation layer and preserves the model
query boundary.

## Task register

| Example | Task | Intended evidence path | Recorded observation and supporting record |
|---|---|---|---|
| `score` | Where did `wasted` go? | Start at `mem2reg`, select `score.c:3`, then move to `instcombine`. | At `mem2reg`, `score.c:3` maps to `%mul1`, `%mul2`, and `%sub`; at `instcombine` it has no mapped instruction. The direct `mem2reg` → `instcombine` correspondence summary records four removed instructions. |
| `score` | Recognise the instruction-form rewrite | Start at `mem2reg`, select `score.c:2`, then move to `instcombine` and inspect the counterpart link. | `%mul = mul nsw i32 %scale, 32` becomes `%mul = shl nsw i32 %scale, 5`. The direct correspondence records the link as approximate and renamed, which is the confidence shown to the learner. |
| `score` | Explain the block collapse | Compare the full CFG at `instcombine` and `simplifycfg`, then inspect the structural result. | The API CFG records change from four basic blocks/four edges to one basic block/no edges. The adjacent correspondence records three removed basic blocks. |
| `binary_search` | Trace a control-flow simplification | Compare the full CFG at `instcombine` and `simplifycfg`. | The API CFG records change from 11 blocks/14 edges to 7 blocks/9 edges. Direct correspondence links mark `if.then`, `if.else`, `if.end`, and `if.then7` as removed blocks. |
| `quick_sort` | Scope the investigation to the partition loop | At the baseline, use full-artefact navigation to select `partition`, then compare its CFG with `quick_sort`. | The baseline `quick_sort` function has three basic blocks; `partition` has seven blocks and eight edges. Function-scoped API records support the prompt's scope choice. |

## Evaluation use

These tasks support a short case study or small study: they ask the learner to
locate, compare, and explain one source-to-IR or CFG observation, then make a
reviewable answer available. A facilitator can record the selected task, the
state identifiers named in the evidence path, and whether the learner used the
answer disclosure. The expected observations remain inspectable through the
same source mappings, API CFG responses, and correspondence evidence as the
interface.
