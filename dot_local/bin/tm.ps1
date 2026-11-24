# tm [DIR]: open DIR's sesh session, or pick one with tv's sesh channel. Windows counterpart of ./executable_tm.
param([string]$Dir)
# psmux popups get PSMUX_TARGET_SESSION but no TMUX, so sesh would attach inside the popup instead of
# switching the client. TMUX names the session's server by the port psmux keeps in ~/.psmux/<session>.port.
$port = "$HOME\.psmux\$env:PSMUX_TARGET_SESSION.port"
if (-not $env:TMUX -and $env:PSMUX_TARGET_SESSION -and (Test-Path $port)) { $env:TMUX = "/tmp/psmux-0/default,$(Get-Content $port),0" }
if ($Dir) { sesh connect (Resolve-Path $Dir).Path; exit $LASTEXITCODE }
$choice = tv sesh
if ($choice) { sesh connect $choice }
