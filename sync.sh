#!/usr/bin/env bash
# Bouwt de previewrepo op uit pages.tsv (de sitestructuur uit de spreadsheet)
# en pusht naar GitHub Pages. Elke regel in pages.tsv wordt een map, zodat
# de preview-URL exact het pad uit de spreadsheet volgt.
#
#   /hoogeveen/egym/  ->  https://jasperk1107.github.io/connectfit-pages/hoogeveen/egym/
set -euo pipefail

SRC="/Users/jasperkoekoek/PPC OS/clients/connectfit/created/landing-pages"
DST="$(cd "$(dirname "$0")" && pwd)"
PREFIX="/connectfit-pages"
BASE="https://jasperk1107.github.io${PREFIX}"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

css='body{font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;color:#111;background:#fff;max-width:920px;margin:0 auto;padding:32px 20px}
h1{font-size:22px;margin:0 0 4px}p.sub{color:#666;margin:0 0 26px}
table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:8px 10px;border-bottom:1px solid #e8e8e8;vertical-align:top}
th{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:#777;border-bottom:2px solid #111}
a{color:#0b57d0}code{font:12px/1.4 ui-monospace,SFMono-Regular,Menlo,monospace;background:#f5f5f5;padding:2px 5px;border-radius:3px;word-break:break-all}
td.n{white-space:nowrap}td.kw{color:#666;font-size:13px}
.s{font-size:11px;padding:2px 7px;border-radius:10px;white-space:nowrap}
.live{background:#e3f0e4;color:#1d6b28}.todo{background:#f0efe3;color:#77682a}'

mk_placeholder () { # $1=naam $2=pad $3=keyword $4=doelbestand
  cat <<HTML
<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>$1 — nog te bouwen | ConnectFit</title>
<style>$css</style>
<h1>$1</h1>
<p class="sub">Deze pagina is nog niet gebouwd. De URL staat vast en kan al in de spreadsheet.</p>
<table>
<tr><th>Pad</th><td><code>$2</code></td></tr>
<tr><th>Hoofdzoekwoord</th><td>${3:-—}</td></tr>
<tr><th>Preview-URL</th><td><code>${BASE}$2</code></td></tr>
</table>
<p style="margin-top:26px"><a href="${PREFIX}/overzicht/">Terug naar het overzicht</a></p>
HTML
}

# --- pagina's bouwen ---
while IFS=$'\t' read -r path naam kw bron; do
  [ -z "${path:-}" ] && continue
  dir="$BUILD${path}"
  mkdir -p "$dir"
  if [ -n "${bron:-}" ] && [ -f "$SRC/$bron" ]; then
    # root-absolute links en relatieve assets naar het projectpad trekken,
    # zodat navigatie tussen de previews blijft werken
    perl -pe "s{(href|src)=\"/(?!/)}{\$1=\"${PREFIX}/}g; s{(href|src)=\"(?![/#?]|https?:|mailto:|tel:|data:|javascript:)}{\$1=\"${PREFIX}/}g" \
      "$SRC/$bron" > "$dir/index.html"
  else
    mk_placeholder "$naam" "$path" "$kw" > "$dir/index.html"
  fi
done < "$DST/pages.tsv"

mkdir -p "$BUILD/assets"
cp "$SRC"/assets/* "$BUILD/assets/" 2>/dev/null || true
cp "$SRC"/*.css "$BUILD/" 2>/dev/null || true
printf 'User-agent: *\nDisallow: /\n' > "$BUILD/robots.txt"

# --- overzicht bouwen, in de volgorde van pages.tsv ---
{
  echo '<!doctype html>'
  echo '<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
  echo '<meta name="robots" content="noindex,nofollow">'
  echo '<title>ConnectFit sitestructuur</title>'
  echo "<style>$css</style>"
  echo '<h1>ConnectFit sitestructuur</h1>'
  echo '<p class="sub">Previews in de volgorde van de spreadsheet. Het pad is gelijk aan dat van de echte site, dus de preview-URL is de basis plus het pad.</p>'
  echo '<table><tr><th>#</th><th>Pagina</th><th>Pad</th><th>Status</th><th>Hoofdzoekwoord</th></tr>'
  i=0
  while IFS=$'\t' read -r path naam kw bron; do
    [ -z "${path:-}" ] && continue
    i=$((i+1))
    if [ -n "${bron:-}" ] && [ -f "$SRC/$bron" ]; then s='<span class="s live">gebouwd</span>'; else s='<span class="s todo">nog te bouwen</span>'; fi
    printf '<tr><td class="n">%s</td><td class="n"><a href="%s%s">%s</a></td><td><code>%s</code></td><td>%s</td><td class="kw">%s</td></tr>\n' \
      "$i" "$PREFIX" "$path" "$naam" "$path" "$s" "${kw:-—}"
  done < "$DST/pages.tsv"
  echo '</table>'
  printf '<p class="sub" style="margin-top:24px">Basis: <code>%s</code> &middot; bijgewerkt %s</p>\n' "$BASE" "$(date '+%d-%m-%Y %H:%M')"
} > "$BUILD/overzicht-index.html"
mkdir -p "$BUILD/overzicht" && mv "$BUILD/overzicht-index.html" "$BUILD/overzicht/index.html"

# --- naar de repo spiegelen, oude bestanden weg ---
rsync -a --delete \
  --exclude '.git' --exclude 'sync.sh' --exclude 'pages.tsv' --exclude 'README.md' \
  "$BUILD"/ "$DST"/

cd "$DST"
git add -A
if git diff --cached --quiet; then
  echo "Niets gewijzigd."
else
  git commit -q -m "Sync sitestructuur $(date '+%Y-%m-%d %H:%M')"
  git push -q
  echo "Gepusht. Live over ~1 minuut."
fi
echo "Overzicht: ${BASE}/overzicht/"
