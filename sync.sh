#!/usr/bin/env bash
# Kopieert de landingspagina's uit de PPC OS workspace naar deze repo,
# bouwt index.html opnieuw en pusht naar GitHub Pages.
set -euo pipefail

SRC="/Users/jasperkoekoek/PPC OS/clients/connectfit/created/landing-pages"
DST="$(cd "$(dirname "$0")" && pwd)"
BASE="https://jasperk1107.github.io/connectfit-pages"

mkdir -p "$DST/assets"
cp "$SRC"/*.html "$DST"/
cp "$SRC"/assets/* "$DST/assets/" 2>/dev/null || true

# --- index.html opbouwen ---
{
cat <<'HTML'
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>ConnectFit landingspagina's</title>
<style>
  body{font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;
       max-width:900px;margin:0 auto;padding:32px 20px;color:#111;background:#fff}
  h1{font-size:22px;margin:0 0 4px}
  p.sub{color:#666;margin:0 0 28px}
  table{border-collapse:collapse;width:100%}
  th,td{text-align:left;padding:9px 10px;border-bottom:1px solid #e6e6e6;vertical-align:top}
  th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:#777;border-bottom:2px solid #111}
  a{color:#0b57d0}
  code{font:12px/1.4 ui-monospace,SFMono-Regular,Menlo,monospace;color:#444;
       background:#f5f5f5;padding:2px 5px;border-radius:3px;word-break:break-all}
  td.d{white-space:nowrap;color:#777;font-size:13px}
</style>
<h1>ConnectFit landingspagina's</h1>
<p class="sub">Previews voor intern gebruik en klantfeedback. Niet indexeerbaar.</p>
<table>
<tr><th>Pagina</th><th>Datum</th><th>URL</th></tr>
HTML

for f in "$DST"/*.html; do
  n="$(basename "$f")"
  [ "$n" = "index.html" ] && continue
  # datum uit de bestandsnaam (YYYY-MM-DD aan het eind)
  d="$(echo "$n" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tail -1)"
  # titel uit de <title>-tag, anders de bestandsnaam
  t="$(sed -n 's:.*<title>\(.*\)</title>.*:\1:p' "$f" | head -1)"
  [ -z "$t" ] && t="${n%.html}"
  printf '<tr><td><a href="%s">%s</a></td><td class="d">%s</td><td><code>%s/%s</code></td></tr>\n' \
    "$n" "$t" "${d:-—}" "$BASE" "$n"
done

echo "</table>"
printf '<p class="sub" style="margin-top:24px">Bijgewerkt: %s</p>\n' "$(date '+%d-%m-%Y %H:%M')"
} > "$DST/index.html"

printf 'User-agent: *\nDisallow: /\n' > "$DST/robots.txt"

cd "$DST"
git add -A
if git diff --cached --quiet; then
  echo "Niets gewijzigd."
else
  git commit -q -m "Sync landingspagina's $(date '+%Y-%m-%d %H:%M')"
  git push -q
  echo "Gepusht. Live over ~1 minuut: $BASE/"
fi
