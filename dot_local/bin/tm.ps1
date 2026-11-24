# tm [DIR]: open DIR's sesh session, or pick one with tv's sesh channel. Windows counterpart of ./executable_tm.
param([string]$Dir)
# psmux runs a server per session, and each keeps the environment of whatever started it, so TMUX in a popup
# is missing or names another session's server: sesh would attach inside the popup, or switch nothing.
# PSMUX_TARGET_SESSION is right in popups; a pane from psmux's warm pool says __warm__, but its TMUX is right.
# TMUX names a server by the port psmux keeps in ~/.psmux/<session>.port.
$s = $env:PSMUX_TARGET_SESSION
if ($s -and $s -ne '__warm__' -and (Test-Path ($port = "$HOME\.psmux\$s.port"))) { $env:TMUX = "/tmp/psmux-0/default,$(Get-Content $port),0" }
if ($Dir) { sesh connect (Resolve-Path $Dir).Path; exit $LASTEXITCODE }
$choice = tv sesh
if ($choice) { sesh connect $choice }
