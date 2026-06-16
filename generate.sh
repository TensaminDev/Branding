#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$ROOT"
OUT="$ROOT/gen"
TMP="${TMPDIR:-/tmp}/tensamin-branding-generate-$$"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_command inkscape
require_command magick
require_command perl

mkdir -p "$OUT" "$TMP"

cp "$BASE/logo_raw.svg" "$OUT/logo_square.svg"
perl -0pi -e '
  s/width="84\.12928mm"/width="90mm"/;
  s/height="88\.726425mm"/height="90mm"/;
  s/viewBox="0 0 84\.12928 88\.726425"/viewBox="0 0 90 90"/;
  s/sodipodi:docname="tensamin\.svg"/sodipodi:docname="logo_square.svg"/;
  s/matrix\(0\.78671048,0,0,0\.83608014,-119\.72576,-51\.488345\)/matrix(0.78671048,0,0,0.83608014,-116.36038,-50.640745)/;
  s/(inkscape:label="foreground"\n\s+style="stroke:url\(#linearGradient16\);stroke-width:0\.5;stroke-dasharray:none")/$1\n       transform="translate(3.3653788,0.84760028)"/;
' "$OUT/logo_square.svg"

cp "$BASE/logo_raw_outline.svg" "$OUT/logo_square_outline.svg"
perl -0pi -e '
  s/width="85\.836182mm"/width="90.476906mm"/;
  s/height="90\.476906mm"/height="90.476906mm"/;
  s/viewBox="0 0 85\.836183 90\.476906"/viewBox="0 0 90.476906 90.476906"/;
  s/sodipodi:docname="logo_raw_outline\.svg"/sodipodi:docname="logo_square_outline.svg"/;
  s/transform="matrix\(0\.77770172,0,0,0\.82714179,101\.85385,-33\.291714\)"/transform="matrix(0.77770172,0,0,0.82714179,104.17421,-33.291714)"/;
  s/transform="matrix\(0\.98854883,0,0,0\.98930922,3\.7119485,1\.7325084\)"/transform="matrix(0.98854883,0,0,0.98930922,6.03231,1.7325084)"/;
  s/transform="matrix\(0\.98854883,0,0,0\.98930922,220\.2086,17\.64618\)"/transform="matrix(0.98854883,0,0,0.98930922,222.52896,17.64618)"/;
' "$OUT/logo_square_outline.svg"

inkscape --export-dpi=300 --export-type=png --export-filename="$OUT/logo_square.png" "$OUT/logo_square.svg"
inkscape --export-dpi=300 --export-type=png --export-filename="$OUT/logo_square_outline.png" "$OUT/logo_square_outline.svg"
magick "$OUT/logo_square_outline.png" -resize 96x96 "$OUT/favicon-96x96.png"
magick "$OUT/logo_square_outline.png" -resize 180x180 "$OUT/apple-touch-icon.png"
magick "$OUT/logo_square_outline.png" -resize 512x512 "$OUT/web-app-manifest-512x512.png"
magick "$OUT/logo_square_outline.png" \
  \( -clone 0 -resize 16x16 \) \
  \( -clone 0 -resize 32x32 \) \
  \( -clone 0 -resize 48x48 \) \
  -delete 0 "$OUT/favicon.ico"

inkscape --export-type=png --export-filename="$TMP/logo_raw.png" "$BASE/logo_raw.svg"
inkscape --export-type=png --export-filename="$TMP/logo_raw_outline.png" "$BASE/logo_raw_outline.svg"

magick "$TMP/logo_raw.png" -bordercolor none -border 60 "$OUT/logo_padded.png"
magick "$TMP/logo_raw_outline.png" -bordercolor none -border 60 "$OUT/logo_padded_outline.png"
magick "$TMP/logo_raw_outline.png" -bordercolor none -border 120 "$OUT/logo_padded_extreme_outline.png"
magick "$TMP/logo_raw_outline.png" -bordercolor none -border 180 "$OUT/logo_padded_extra_extreme_outline.png"

magick "$BASE/gradiant.png" -crop 1080x1080+1380+540 +repage -resize 1134x1134! "$TMP/bg_base.png"

magick "$TMP/logo_raw.png" -resize 599x625! "$TMP/logo_bg_small_overlay.png"
magick "$TMP/bg_base.png" "$TMP/logo_bg_small_overlay.png" -gravity center -compose over -composite "$OUT/logo_bg_small.png"

magick "$TMP/logo_raw.png" -resize 842x861! "$TMP/logo_bg_big_overlay.png"
magick "$TMP/bg_base.png" "$TMP/logo_bg_big_overlay.png" -gravity center -compose over -composite "$OUT/logo_bg_big.png"

printf 'Generated assets in %s\n' "$OUT"
