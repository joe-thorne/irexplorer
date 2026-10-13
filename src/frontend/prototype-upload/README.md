# Upload-flow prototype (throwaway)

**Question ([irexplorer#47](https://github.com/joe-thorne/irexplorer/issues/47)):** how should M1 user-program upload look and behave in the Explore page? Where does uploading live, file picker or paste, how do compiling and failure look, and how does a compiled user program load into the same source, panel and comparison views as a curated example?

This branch (`prototype/upload-flow`) is a primary source, not production code. It never merges. The decided behaviour is rewritten properly in the M1 build.

## Run

```sh
scripts/prototype_upload.sh
```

Open <http://127.0.0.1:8010/?variant=A#/explore>. Switch variants with the floating bar or the ← and → keys. **Scenarios** opens a tray containing:

- sample files to "choose";
- the next server outcome (`compile_failed`, a parser failure, `compile_timeout` with a real 30 s wait, `compiler_busy`, `compiler_unavailable`);
- the compile time;
- **Restart server**, which forgets every program, so the next request gets `unknown_program`;
- whether the browser keeps uploads across a reload;
- a readout of what the server and the browser hold.

Your own `.c` files work too. In C, set the next outcome before opening the dialog, because the modal dialog makes the tray inert.

## What is stubbed

- `stub-server.js` answers `POST /api/programs` and `/api/programs/{programId}/…` in the browser. It never compiles. A program is backed by the curated example whose source it matches, or a guess from its function names, so the IR, CFG and comparison are that example's. Line links are correct only for the samples that copy a curated source. Its compile errors are recognised patterns, not clang. Its "server memory" (up to 16 programs) survives a reload until **Restart server**.
- `program-client.js` holds the shared browser behaviour from irexplorer#44 and #46: the checks made before posting, the synchronous compile with an elapsed-seconds tick, the kept sources, and the silent re-post on `unknown_program`.
- `app.js` changes one line: `apiRoot` serves `program:<id>` from `/api/programs/<id>`.

## Variants

| | A · File selector | B · Source drop zone | C · Dialog |
|---|---|---|---|
| Where upload lives | An "Upload a C file…" entry at the end of the File select | A Curated / Your files switch in the source panel; the source pane becomes a drop zone | A "Compile your own C file…" button beside the Explore heading |
| Input | File picker only | Picker, drag and drop, or paste (with a file name) | Picker or paste, in tabs |
| Checks before sending | Shown only as a refusal | Shown only as a refusal | Live checklist; Compile is enabled only when every check passes |
| While compiling | A status line under File ("Compiling X… 3 s"). The comparison on screen stays usable, but the File select is disabled | The uploaded source appears at once (dimmed); a compile card replaces the panels | Progress inside the dialog, with Cancel; the page is unchanged |
| Failure | An alert box under File, with source excerpts; the previous comparison stays | A card in place of the panels; error lines are marked in the source, and each diagnostic jumps to its line | Inside the dialog, with source excerpts; Back, Try again, Close |
| Telling `score.c` from curated `score` | "Curated examples" and "Your uploads" groups | Separate selects per mode, plus a "Your file" chip | "score.c · uploaded" in one list, plus an "Uploaded" chip |
| Renamed file | "Uploaded “My Program (2).c” as My_Program_2_.c." under File | "Renamed from …" under the controls | "Will be compiled as …" before compiling |
| `unknown_program` | A "Recompiling X: the server no longer had it… 3 s" status | A compile card | A banner under the heading |

All three variants share these behaviours:

- The upload control is disabled during the browser's own compile.
- The elapsed seconds are `aria-hidden`, and the status text is announced once.
- The same file returns the same id at once.
- Study never builds any of it.
