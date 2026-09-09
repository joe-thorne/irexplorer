# Accessibility

The interface uses labelled native controls, visible focus indicators, a skip link, heading focus on study navigation, and live status messages. Source lines, IR instructions, and CFG blocks support keyboard selection. Correspondence is described in text and through pressed states and outlines as well as colour. CFG edges also have a text representation.

The comparison workspace has two independently configured panes and a shared function selector. Narrow layouts stack the panes and bound their scrolling regions. Graphs provide width fitting and explicit zoom choices. Reduced-motion and forced-colour preferences have dedicated styles.

Study forms use fieldsets, legends, labelled inputs, text validation messages, and focus on invalid controls. Draft and submission failures remain visible and preserve retry options.

The [test suite](../tests/README.md) includes interface and browser checks. These checks do not establish full accessibility conformance. Physical keyboard, spoken screen-reader, zoom, and platform-specific behaviour require manual assessment.
