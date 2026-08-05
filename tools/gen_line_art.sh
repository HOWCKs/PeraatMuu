#!/usr/bin/env bash
# Gera arte de linha neon para consoles sem imagem AI (mesmo estilo visual
# dos emblemas gerados por IA: fundo violeta escuro, traços ciano/magenta,
# grade synthwave). Roda com ImageMagick 6 (convert) — sem delegados extras.
#
# Uso: bash tools/gen_line_art.sh <id ...>   (sem args = todos os pendentes)
set -euo pipefail
OUT=assets/consoles
W=512; H=288; BG="#12081F"
CY="rgba(34,230,255,0.28)"; CC="#22E6FF"
MY="rgba(255,61,242,0.28)"; MC="#FF3DF2"
DK="#1B0F33"

# emit <id> <forma...>   forma = "GEOMETRIA|COR[|fill]"
emit() {
  local id="$1"; shift
  local args=( -size "${W}x${H}" "xc:${BG}" )
  local f y s geom rest cor fill glow
  for f in "64,288 256,150" "448,288 256,150" "160,288 256,150" "352,288 256,150"; do
    args+=( -stroke "rgba(140,60,255,0.20)" -strokewidth 1 -fill none -draw "line $f" )
  done
  for y in 210 240 268; do
    args+=( -stroke "rgba(140,60,255,0.20)" -strokewidth 1 -fill none -draw "line 0,$y 512,$y" )
  done
  for s in "$@"; do
    geom="${s%%|*}"; rest="${s#*|}"; cor="${rest%%|*}"; fill="${rest#*|}"
    glow="$CY"; [ "$cor" = "$MC" ] && glow="$MY"
    if [ "$fill" = "fill" ]; then
      args+=( -stroke none -fill "$DK" -draw "$geom" )
      args+=( -stroke "$glow" -strokewidth 12 -fill none -draw "$geom" )
      args+=( -stroke "$cor" -strokewidth 2 -fill none -draw "$geom" )
    else
      args+=( -stroke "$glow" -strokewidth 12 -fill none -draw "$geom" )
      args+=( -stroke "$cor" -strokewidth 3 -fill none -draw "$geom" )
    fi
  done
  convert "${args[@]}" "$OUT/$id.jpg"
  echo "  ok $id"
}

art_nds() {   # clamshell de tela dupla
  emit nds \
    "rectangle 166,58 346,150|$CC|fill" \
    "rectangle 180,72 332,138|$MC|" \
    "rectangle 166,158 346,240|$CC|fill" \
    "rectangle 190,172 250,226|$CC|" \
    "circle 300,199 300,189|$MC|" \
    "circle 320,209 320,203|$MC|" \
    "rectangle 250,152 262,158|$CC|"
}

art_3ds() {   # clamshell + circle pad + tela touch maior
  emit 3ds \
    "roundrectangle 160,52 352,148,10,10|$CC|fill" \
    "roundrectangle 174,66 338,136,6,6|$MC|" \
    "roundrectangle 160,156 352,244,10,10|$CC|fill" \
    "roundrectangle 196,168 338,232,6,6|$CC|" \
    "circle 178,200 178,190|$MC|" \
    "circle 292,205 292,197|$MC|" \
    "circle 312,195 312,190|$MC|" \
    "rectangle 248,150 264,156|$CC|"
}

art_gba() {
  emit gba \
    "circle 116,150 116,96|$CC|" \
    "circle 396,150 396,96|$CC|" \
    "rectangle 116,96 396,96|$CC|" \
    "rectangle 116,204 396,204|$CC|" \
    "line 116,96 116,204|$CC|" \
    "line 396,96 396,204|$CC|" \
    "roundrectangle 190,104 322,196,12,12|$MC|fill" \
    "line 150,150 150,150|$CC|" \
    "line 148,138 160,162|$CC|" \
    "line 160,138 148,162|$CC|" \
    "circle 352,138 352,130|$MC|" \
    "circle 366,156 366,148|$MC|"
}

art_psp() {   # widescreen fino
  emit psp \
    "roundrectangle 76,104 436,196,28,28|$CC|fill" \
    "rectangle 160,118 392,182|$MC|" \
    "line 112,138 136,150|$CC|" \
    "line 136,138 112,150|$CC|" \
    "circle 400,134 400,128|$MC|" \
    "circle 414,148 414,142|$MC|" \
    "circle 400,162 400,156|$MC|" \
    "circle 386,148 386,142|$MC|" \
    "line 160,190 392,190|$CC|"
}

art_ws() {    # horizontal fininho com tela quadrada
  emit ws \
    "roundrectangle 96,108 416,188,18,18|$CC|fill" \
    "rectangle 190,120 322,176|$MC|" \
    "line 128,148 158,148|$CC|" \
    "line 143,133 143,163|$CC|" \
    "circle 366,140 366,134|$MC|" \
    "circle 380,158 380,152|$MC|"
}

art_arcade() { # gabinete com marquee e painel
  emit arcade \
    "rectangle 166,56 346,96|$MC|fill" \
    "rectangle 156,96 356,170|$CC|fill" \
    "rectangle 176,106 336,160|$MC|" \
    "polygon 156,170 356,170 380,206 132,206|$CC|fill" \
    "circle 190,188 190,182|$MC|" \
    "circle 250,190 250,184|$MC|" \
    "circle 274,190 274,184|$MC|" \
    "circle 298,190 298,184|$MC|" \
    "line 190,196 190,182|$CC|" \
    "rectangle 156,206 356,240|$CC|fill" \
    "rectangle 236,214 276,232|$MC|"
}

art_ps1() {   # caixa cinza com tampa redonda
  emit ps1 \
    "rectangle 126,96 386,200|$CC|fill" \
    "circle 256,132 256,80|$MC|" \
    "line 126,168 386,168|$CC|" \
    "rectangle 146,176 196,186|$CC|" \
    "circle 360,181 360,176|$MC|"
}

art_n64() {   # controle tridente
  emit n64 \
    "ellipse 256,120 64,44 0,360|$CC|fill" \
    "line 202,140 176,224|$CC|" \
    "line 310,140 336,224|$CC|" \
    "line 244,150 244,214|$CC|" \
    "line 268,150 268,214|$CC|" \
    "line 244,214 268,214|$CC|" \
    "circle 256,118 256,106|$MC|" \
    "circle 214,116 214,108|$MC|" \
    "circle 298,116 298,108|$MC|"
}

art_ps2() {   # torre vertical com ranhuras
  emit ps2 \
    "rectangle 206,44 306,246|$CC|fill" \
    "line 222,70 248,70|$MC|" \
    "line 222,86 248,86|$MC|" \
    "line 222,102 248,102|$MC|" \
    "circle 266,150 266,120|$CC|" \
    "line 206,220 306,220|$MC|" \
    "rectangle 186,246 326,254|$CC|"
}

art_wii() {   # console fino + remote com sensor
  emit wii \
    "roundrectangle 176,66 236,230,10,10|$CC|fill" \
    "line 188,90 224,90|$MC|" \
    "rectangle 168,230 244,238|$CC|" \
    "roundrectangle 300,96 340,232,14,14|$CC|fill" \
    "line 308,124 332,124|$MC|" \
    "line 320,112 320,136|$MC|" \
    "circle 320,160 320,153|$MC|" \
    "circle 320,196 320,191|$CC|"
}

art_gcn() {   # cubo com alça
  emit gcn \
    "rectangle 176,120 316,240|$CC|fill" \
    "polygon 176,120 216,84 356,84 316,120|$CC|fill" \
    "polygon 316,120 356,84 356,204 316,240|$CC|fill" \
    "line 236,96 296,96|$MC|" \
    "circle 216,180 216,168|$MC|" \
    "circle 256,180 256,172|$MC|" \
    "rectangle 196,214 256,224|$CC|"
}

all() {
  art_nds; art_3ds; art_gba; art_psp; art_ws; art_arcade
  art_ps1; art_n64; art_ps2; art_wii; art_gcn
}

if [ $# -eq 0 ]; then all; else for a in "$@"; do "art_$a"; done; fi
