# tm [DIR]: open DIR's sesh session, or pick one with tv's sesh channel. Windows counterpart of ./executable_tm.
param([string]$Dir)
if ($Dir) { sesh connect (Resolve-Path $Dir).Path; exit $LASTEXITCODE }
$choice = tv sesh
if ($choice) { sesh connect $choice }
