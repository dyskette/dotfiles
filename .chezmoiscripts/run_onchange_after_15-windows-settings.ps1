# Explorer settings for this user (HKCU, no admin). Some apply after Explorer restarts or you sign out.
$k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
@{
  HideFileExt                 = 0  # show file extensions
  Hidden                      = 1  # show hidden files
  VirtualDesktopTaskbarFilter = 0  # taskbar: windows from all desktops
  VirtualDesktopAltTabFilter  = 0  # Alt+Tab: windows from all desktops
  MultiTaskingAltTabFilter    = 3  # Alt+Tab: no browser tabs (undocumented; the value the Settings app writes)
}.GetEnumerator() | ForEach-Object { Set-ItemProperty $k $_.Key $_.Value -Type DWord }
