-- Windows speedups first: lazy.nvim and LazyVim already look up and spawn tools (ADR 0008).
local perf = require("fast.perf")
perf.setup()
require("config.lazy")
-- PATH lookup index on a worker thread, after every PATH change made during startup.
perf.prebuild()
