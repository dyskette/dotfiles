// node:test reporter for neotest-nodejs (plugins/test.lua swaps it in for the adapter's own).
// Both write one JSON event per line, but the adapter's drops each Error's message (JSON.stringify
// skips non-enumerable properties), so a failing test only said "testCodeFailure".

const { stripVTControlCharacters } = require("node:util");

/** JSON.stringify replacer: keeps Error messages and causes, survives BigInt and cycles. */
function replacer() {
  const seen = new WeakSet();
  return (_key, value) => {
    if (typeof value === "bigint") return `${value}n`;
    if (value === null || typeof value !== "object") return value;
    if (seen.has(value)) return "[Circular]";
    seen.add(value);
    if (!(value instanceof Error)) return value;
    // No stack: the adapter shows a cause's stack in preference to its message. No colors: when
    // node's stderr is a terminal, assert colors its diffs, and the codes showed up in diagnostics.
    const message = stripVTControlCharacters(value.message);
    return { ...value, name: value.name, message, cause: value.cause };
  };
}

module.exports = async function* neotestNodejsReporter(source) {
  for await (const event of source) {
    yield `${JSON.stringify(event, replacer())}\n`;
  }
};
