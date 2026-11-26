# Explorer settings for this user (HKCU, no admin). Some apply after Explorer restarts or you sign out.
$k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
@{
  HideFileExt                 = 0  # show file extensions
  Hidden                      = 1  # show hidden files
  VirtualDesktopTaskbarFilter = 0  # taskbar: windows from all desktops
  VirtualDesktopAltTabFilter  = 0  # Alt+Tab: windows from all desktops
  MultiTaskingAltTabFilter    = 3  # Alt+Tab: no browser tabs (undocumented; the value the Settings app writes)
}.GetEnumerator() | ForEach-Object { Set-ItemProperty $k $_.Key $_.Value -Type DWord }

# App execution aliases: the Store's python stubs sit on PATH and shadow, or stand in for, mise's Python.
# Turning one off in Settings deletes its link in WindowsApps, so deleting the link is the same switch.
# A Store or App Installer update can bring them back; the next apply that changes this file removes them again.
'python.exe', 'python3.exe' | ForEach-Object { Remove-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\$_" -Force -ErrorAction SilentlyContinue }
