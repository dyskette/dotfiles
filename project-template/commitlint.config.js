/**
 * commitlint config restricted to the organization's Conventional Commit types.
 * @type {import('@commitlint/types').UserConfig}
 */
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [2, "always",
      ["feat", "fix", "chore", "docs", "refactor", "test", "ci", "perf", "style", "build"]],
    "subject-case": [2, "never", ["sentence-case", "start-case", "pascal-case", "upper-case"]],
    "trailer-exists": [2, "never", "Co-authored-by:"],
  },
};
