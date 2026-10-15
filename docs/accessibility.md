# Accessibility

The interface uses labelled native controls, visible focus indicators, a skip link, heading focus on study navigation, and live status messages. Source lines, IR instructions, and CFG blocks support keyboard selection. Correspondence is described in text and through pressed states and outlines as well as colour. CFG edges also have a text representation.

With user programs on, a failed compile lists clang's diagnostics, and a program that compiles with clang warnings lists them in a labelled, collapsed disclosure above its source. Each diagnostic or warning against the program is a button that scrolls to its line and outlines it, and the announcement that the program is ready counts its warnings.

The comparison workspace has two independently configured panels and a shared function selector. Narrow layouts stack the panels and bound their scrolling regions. Graphs provide width fitting and explicit zoom choices. Reduced-motion and forced-colour preferences have dedicated styles.

The user programs editor is a native textarea labelled for screen readers and described by a hint that gives its keys and line count. Tab indents there, so Esc releases Tab for the next press, which then leaves the editor; keyboard users are never trapped in it. Its status line, which counts the lines that are new or changed, is announced when it changes, and its margin marks those lines with a bar that forced colours keep. Edits made with its keys, and **Restore original**, go through the browser's own undo; restoring is announced with the way to undo it, and leaves the keyboard in the editor.

Study forms use fieldsets, legends, labelled inputs, text validation messages, and focus on invalid controls. Draft and submission failures remain visible and preserve retry options.

The [test suite](../tests/README.md) includes interface and browser checks. These checks do not establish full accessibility conformance. Physical keyboard, spoken screen-reader, zoom, and platform-specific behaviour require manual assessment.
