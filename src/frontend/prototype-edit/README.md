# Editing-flow prototype (throwaway)

**Question ([irexplorer#71](https://github.com/joe-thorne/irexplorer/issues/71)):** how should M2 editing look and behave in the Explore page? Which editor works under the `default-src 'self'` policy? Does editing replace the source view or sit beside it? How do "Edit a copy" of a curated example or an uploaded program, starting a blank program, and restoring the original work?

This branch (`prototype/editing-flow`) is a primary source, not production code. It never merges. The behaviour Joe chooses is rewritten properly in the M2 build.

## Run

```sh
scripts/prototype_edit.sh
```

Open <http://127.0.0.1:8011/?variant=A#/explore>. Switch variants with the floating bar or the ← and → keys. **Scenarios** opens a tray with these settings:

- the next compile: as the source says, or `compiler_unavailable`;
- the compile time: 1 s, 4 s (about the emulated compiler) or 9 s, so Cancel can be tried;
- the editor: highlighted, or a plain textarea;
- whether New… starts with a starter function or empty;
- whether a recompiled edit of one of your files replaces it in **Your file** or is added beside it;
- **Restart server**, and a readout of what the server, the list and the edit hold.

The fake compiler reports errors for a missing `;`, an unclosed `{`, `#error`, and the names `totl`, `reslt` and `vlaue`.

## What every variant shares

- **The editor:** a native `<textarea>` laid over the existing C highlighter (`highlightCSource` in `source.js`), with a line-number gutter. Nothing is vendored and nothing needs `'unsafe-inline'`. Its behaviour:
  - Tab indents and Shift+Tab outdents. Esc releases Tab, so the next Tab leaves the editor.
  - Enter keeps the indent. Ctrl/⌘+Enter compiles.
  - ⌘Z undoes everything, including Restore original.
  - A hint counts lines against the 200-line limit.
- **Starting an edit:**
  - **Edit a copy** opens the editor on a curated example. The copy is named `‹example›.c`.
  - **Edit** opens it on one of your files.
  - **New…** replaces M1's **Paste…**: the editor is also where pasted source goes. The drop zone's "Paste source instead" becomes "Write or paste a program".
- **While editing:** the file controls (switch, selects, Upload…, New…) are locked, so you compile or discard first. The status line says "Edited · not compiled · N lines new or changed".
- **Restore original:** puts the original back into the editor, either the curated example or the first upload, however many edits ago.
- **Discard edits** asks first if there are any.
- **Compiling** goes through the real M1 flow and its compiling, failure and Cancel cards:
  - On `compile_failed`, the editor comes back with the error lines marked.
  - Any other failure, or Cancel, leaves M1's card with **Back to editing** added.
  - A compiled edit opens in the panels as a user program. A line under the controls reads "Edited from curated score. Open the original". In **Your file** it is listed as "score.c · edited".

## Variants

| | A · In the source pane | B · Beside the compiled source | C · Separate editing step |
|---|---|---|---|
| Where the editor sits | In the C source pane, in place of the read-only lines | In the panels' place (two columns wide) | Across the whole workbench |
| The panels while editing | Visible and usable, outlined as "Showing the last compile, not your edits" | Hidden until you compile | Hidden, as is the source pane |
| What you edit against | The panels' IR | The compiled source, still in the source pane. Changed lines are marked in the editor's margin | Nothing on screen |
| Compile errors | M1's failure card beside the editor. Its diagnostics jump to the editor's lines | Listed above the editor | Listed above the editor |
| Width for a 200-line file | One column (narrow) | Two columns | Full width |

## What is stubbed or left open

- `stub-server.js` answers `/api/release` (setting on) and `/api/programs` in the browser. It never compiles. A program borrows the IR, CFG and comparison of the curated example with the most matching function names, so line links drift once lines are added or removed.
- `programs.js` gains a prototype seam (`window.ProgramsPrototype`) and a hook on its card. `index.html` loads the prototype.
- The following are left to [Recompiling an edited program](https://github.com/joe-thorne/irexplorer/issues/72) and are only roughed in:
  - which panel states and views survive a recompile (here: none, as M1);
  - how unsaved changes are marked beyond the status line;
  - whether a failed recompile should keep the previous comparison (here it replaces it, as in M1);
  - clang's warnings on a successful compile;
  - whether a recompiled edit replaces its file in **Your file** (a tray setting here).
- Not prototyped: keeping an unsaved draft across a reload, and a vendored editor.
