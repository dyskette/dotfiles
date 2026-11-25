# opencode session list --format json → one line per session for tv's opencode-sessions channel:
# "<title padded>  <updated>\t<id>", after a "+ New session\tnew" line. tv shows the part before the tab.
"+ New session\tnew",
(map(.title // "Untitled session") as $titles
 | ($titles | map(length) | max // 0) as $width
 | to_entries[]
 | $titles[.key] as $title
 | "\($title)\(" " * ($width - ($title | length)) // "")  \(.value.updated / 1000 | floor | strflocaltime("%Y-%m-%d %H:%M"))\t\(.value.id)")
