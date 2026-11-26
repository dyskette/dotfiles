# sesh-dir [START]: pick a folder with lf (Enter, from ~/.config/lf/sesh-dir-cmd) and open its sesh session.
# Windows counterpart of ./executable_sesh-dir.
param([string]$Start = $PWD.Path)
lf -command "source '$HOME/.config/lf/sesh-dir-cmd'" $Start
