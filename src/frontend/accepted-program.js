// What irexplorer accepts as a user program, checked here before anything is sent. The server applies the
// same rules again (src/backend/programs/accepted.py), and both are checked against
// tests/data/user-program-acceptance.json, so change the two together.
window.AcceptedProgram = (() => {
  const MAX_LINES = 200;
  const MAX_BYTES = 16 * 1024;
  const STEM_LENGTH = 64;
  const refused = (reason, message) => ({ ok: false, reason, message });

  // The name saved for the compiler: a lowercase .c, unsafe runs as _, the stem cut to 64 characters.
  function safeFileName(fileName) {
    const match = /^([\s\S]*)\.[cC]$/.exec(fileName);
    if (!match) return null;
    return `${match[1].replace(/[^A-Za-z0-9_-]+/g, "_").slice(0, STEM_LENGTH) || "program"}.c`;
  }

  // How many lines `source` has against the limit: one trailing newline ends the last line rather than
  // starting another, and empty text has none.
  function countLines(source) {
    return source ? source.split("\n").length - (source.endsWith("\n") ? 1 : 0) : 0;
  }

  // { ok: true, fileName, source } with the safe name and normalised source, or { ok: false, reason, message }.
  // The first check that fails gives the reason, in the server's order. `text` is null for a file whose
  // bytes are not UTF-8 (see read). Nothing is ever truncated.
  function accept(fileName, text) {
    const safe = safeFileName(fileName);
    if (!safe) return refused("not_c_file", "Only C files can be compiled: the file name must end in .c.");
    // A lone surrogate, which pasted text can hold, has no UTF-8 encoding either.
    if (text === null || !text.isWellFormed()) return refused("invalid_utf8", "The file is not UTF-8 text.");
    if (text.includes("\0")) return refused("nul_character", "The file contains a NUL character.");
    const source = text.replace(/^﻿/, "").replace(/\r\n?/g, "\n");
    // C's own whitespace; CR is gone by now.
    if (/^[ \t\n\v\f]*$/.test(source)) return refused("empty", "The file is empty or contains only whitespace.");
    const lines = countLines(source);
    if (lines > MAX_LINES) return refused("too_many_lines", `The file has ${lines} lines; up to ${MAX_LINES} are allowed.`);
    const size = new TextEncoder().encode(source).length;
    if (size > MAX_BYTES) {
      return refused("too_large", `The file is ${size} bytes of UTF-8 text; up to 16 KiB (${MAX_BYTES} bytes) is allowed.`);
    }
    return { ok: true, fileName: safe, source };
  }

  // A file's text, or null if its bytes are not UTF-8. A leading BOM is kept, for accept to remove exactly one.
  async function read(file) {
    const bytes = await file.arrayBuffer();
    try {
      return new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(bytes);
    } catch {
      return null;
    }
  }

  return { accept, read, countLines, safeFileName, MAX_LINES };
})();
