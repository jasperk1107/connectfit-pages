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
.live{background:#e3f0e4;color:#1d6b28}.todo{background:#f0efe3;color:#77682a}
p.auto{background:#eef4fd;border-left:3px solid #0b57d0;color:#1b3a6b;font-size:13px;padding:10px 14px;margin:0 0 24px;border-radius:0 4px 4px 0}'

# Overzicht krijgt meer breedte: 7 kolommen passen niet in 920px, waardoor het
# pad per teken afbrak. Paden en zoekwoorden nooit meer breken, tabel scrolt.
css_ov="$css
body{max-width:none;padding:32px 28px}
.scroll{overflow-x:auto;-webkit-overflow-scrolling:touch}
table{min-width:1180px}
td code{white-space:nowrap;word-break:normal}
th:nth-child(3),td:nth-child(3){white-space:nowrap;width:1%}
th:nth-child(2),td:nth-child(2){min-width:170px}
td.kw{white-space:nowrap}
td.meta{font-size:13px;color:#333;min-width:230px}
.len{display:inline-block;margin-left:6px;font:11px/1 ui-monospace,SFMono-Regular,Menlo,monospace;color:#8a8a8a;background:#f5f5f5;padding:3px 6px;border-radius:3px;vertical-align:1px}"

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
  echo "<style>$css_ov</style>"
  echo '<h1>ConnectFit sitestructuur</h1>'
  echo '<p class="sub">Previews in de volgorde van de spreadsheet. Het pad is gelijk aan dat van de echte site, dus de preview-URL is de basis plus het pad. Elke pagina opent in een nieuw tabblad.</p>'
  echo '<p class="auto">Dit overzicht werkt zichzelf bij. Zodra een pagina in de werkmap verandert, staat hij binnen een minuut hier.</p>'
  echo '<div class="scroll">'
  echo '<table><tr><th>#</th><th>Pagina</th><th>Pad</th><th>Status</th><th>Hoofdzoekwoord</th><th>Meta title</th><th>Meta description</th></tr>'
  i=0
  while IFS=$'\t' read -r path naam kw bron; do
    [ -z "${path:-}" ] && continue
    i=$((i+1))
    if [ -n "${bron:-}" ] && [ -f "$SRC/$bron" ]; then s='<span class="s live">gebouwd</span>'; else s='<span class="s todo">nog te bouwen</span>'; fi
    f="$BUILD${path}index.html"
    mt=$(perl -0ne 'print $1 if m{<title>(.*?)</title>}s' "$f" 2>/dev/null)
    md=$(perl -0ne 'print $1 if m{<meta\s+name="description"\s+content="(.*?)"}s' "$f" 2>/dev/null)
    if [ -n "$mt" ]; then mtc="$mt <span class=\"len\">${#mt}</span>"; else mtc='<span class="s todo">ontbreekt</span>'; fi
    if [ -n "$md" ]; then mdc="$md <span class=\"len\">${#md}</span>"; else mdc='<span class="s todo">ontbreekt</span>'; fi
    printf '<tr><td class="n">%s</td><td class="n"><a href="%s%s" target="_blank" rel="noopener">%s</a></td><td><code>%s</code></td><td>%s</td><td class="kw">%s</td><td class="meta">%s</td><td class="meta">%s</td></tr>\n' \
      "$i" "$PREFIX" "$path" "$naam" "$path" "$s" "${kw:-—}" "$mtc" "$mdc"
  done < "$DST/pages.tsv"
  echo '</table></div>'
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
