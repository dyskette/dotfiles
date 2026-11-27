// node:test reporter for neotest-nodejs (plugins/test.lua swaps it in for the adapter's own).
// Both write one JSON event per line, but the adapter's drops each Error's message (JSON.stringify
// skips non-enumerable properties), so a failing test only said "testCodeFailure".

/** JSON.stringify replacer: keeps Error messages and causes, survives BigInt and cycles. */
function replacer() {
  const seen = new WeakSet();
  return (_key, value) => {
    if (typeof value === "bigint") return `${value}n`;
    if (value === null || typeof value !== "object") return value;
    if (seen.has(value)) return "[Circular]";
    seen.add(value);
    // No stack: the adapter shows a cause's stack in preference to its message.
    return value instanceof Error ? { ...value, name: value.name, message: value.message, cause: value.cause } : value;
  };
}

module.exports = async function* neotestNodejsReporter(source) {
  for await (const event of source) {
    yield `${JSON.stringify(event, replacer())}\n`;
  }
};
