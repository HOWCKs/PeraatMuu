# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [1.3.0] - 2026-08-05

### Adicionado
- **Nintendo DS jogável (melonDS, experimental):** duas telas empilhadas
  e **tela sensível ao toque funcionando** — toque na metade de baixo do
  vídeo para usar a caneta.
- **PSP (PPSSPP) e Nintendo 64 (Mupen64Plus-Next) experimentais:** a ponte
  nativa agora negocia **renderização por hardware (OpenGL ES)** — o
  núcleo desenha direto na GPU. Jogos leves rodam em aparelhos simples;
  jogos 3D pesados pedem um celular mais forte.
- **PS2, GameCube, Wii e Nintendo 3DS no catálogo** como "EM BREVE", com
  explicação honesta do motivo (núcleos só existem para 64-bit com GPU
  forte — chegam quando o app tiver versão 64-bit pesada).
- **Imagem representando cada console** nos cards e no cabeçalho da tela
  do console (arte neon em estilo synthwave).
- **Descrição de cada console** ("o que é esse console") na tela de
  detalhes, em linguagem simples.
- **Ícones vetoriais nos botões virtuais:** setas do D-pad, START, SELECT
  e os presets do editor viraram vetores desenhados — sem glifos que o
  celular renderizava como emoji colorido.
- **Escolha manual de console para extensões ambíguas:** ao adicionar um
  arquivo .iso/.pbp pelo botão ＋, o app pergunta se é PS1 ou PSP.

### Alterado
- **Navegação ainda mais leve:** no modo "Reduzir animações" as trocas de
  tela são instantâneas e sombras/brilhos custosos são desligados —
  pensado para aparelhos de 2 GB de RAM.
- Carregamento do jogo agora acontece na thread GL (necessário para os
  núcleos com GPU, sem afetar os demais).

## [1.2.0] - 2026-08-05

### Adicionado
- **Controles totalmente personalizáveis:** no menu ≡ do jogo > Controles,
  cada botão pode ser movido (arrastar), redimensionado (slider) e ter o
  ícone trocado — presets de texto ou **imagem importada da memória**
  (PNG/JPG). Layout salvo automaticamente.
- **Acelerar velocidade até 5×** (fast-forward, ideal para pular cutscenes
  e intros) — áudio é pausado durante a aceleração.
- **Modos de tela:** ajustar (proporção), preencher (tela toda), recortar
  (preencher mantendo proporção) e preciso (escala inteira por pixels).
- **Ajustes de cor:** brilho, contraste e saturação via shader nativo.
- **Cheats:** adicione códigos por jogo (GameShark GB, Pro Action Replay
  SNES, CodeBreaker GBA ou "0xEND=0xVAL" bruto), ative/desative e remova.
  Aplicados na RAM emulada a cada quadro.
- **Menu do jogo no visual PeraatMuu** (antes era o diálogo padrão branco).
- **Feedback tátil** ao pressionar botões (motor de vibração VIRTUAL_KEY).
- **Modo "Reduzir animações"** (ligado por padrão em Ajustes > Desempenho):
  desliga varredura animada e tilt 3D — navegação muito mais fluida.

### Alterado
- Interface sem emojis — só glifos/ícones consistentes com o tema.

## [1.1.1] - 2026-08-05

### Corrigido
- **"O núcleo não conseguiu abrir esta ROM" (crítico):** o gambatte atual do
  buildbot libretro só aceita a ROM entregue em MEMÓRIA (`data`+`size`) e
  recusava silenciosamente o modo arquivo (`path`). A ponte nativa agora
  entrega o conteúdo em memória para cartuchos (GB, NES, GBA, SNES, MD...)
  e em streaming por caminho para conteúdo de CD/pesado (.cue/.chd/.iso/.zip),
  com retentativa automática no modo alternativo se o núcleo recusar.
  Smoke test nativo valida o modo de entrega por extensão.

## [1.1.0] - 2026-08-05

### Adicionado
- **ESCOLHER ROM (modo arquivo):** novo fluxo via seletor de ARQUIVO do
  Android — dá pra tocar direto na ROM baixada no gerenciador, uma ou várias
  por vez. A pasta do arquivo passa a ser monitorada automaticamente, então
  as próximas ROMs que caírem ali aparecem sozinhas. Arquivos que o Android
  só devolve como cópia temporária são importados para uma pasta própria.
- Botão **+ ROMS** (início) agora pergunta: ARQUIVO (tocar na ROM) ou PASTA
  (varrer tudo). Biblioteca vazia ganhou botão "ESCOLHER ROM" + "ADICIONAR
  PASTA".

### Corrigido
- Seletor de PASTAS do Android não seleciona arquivos — quem tocava na ROM
  não via nada acontecer. Agora o app mostra um aviso antes, explicando
  para usar o botão "USAR ESTA PASTA" na parte de baixo da tela do sistema.

## [1.0.1] - 2026-08-05

### Corrigido
- **Núcleos invisíveis no app (crítico):** os arquivos `.so` dos núcleos iam
  para o APK com o nome do buildbot (`snes9x_libretro_android.so`), mas o
  Android só extrai libs com prefixo `lib` de `lib/<abi>/` para
  `nativeLibraryDir`. Resultado: todos os núcleos apareciam como "ausente"
  em Ajustes e nenhum jogo iniciava. Agora o download renomeia para
  `lib<snes9x>_libretro_android.so` (`tools/download_cores.sh`) e o app
  procura pelo novo nome.

### Adicionado
- **ROMs em .zip:** a varredura abre cada `.zip` e detecta o console pela
  extensão da ROM interna (ex.: "pokemon.zip" com ".gb" dentro → Game Boy).
  `.bin`/`.iso` acima de 32 MB é tratado como imagem de PS1; romsets de
  arcade (chunks sem extensão conhecida) viram ARCADE. Na primeira jogada a
  ROM é extraída automaticamente para o cache (pares `.cue`/`.bin` vão
  juntos) e reutilizada nas próximas.
- **Atualização automática da biblioteca:** baixou uma ROM nova pelo
  navegador ou moveu arquivos no gerenciador? Ao voltar para o app a
  biblioteca varre as pastas monitoradas sozinha — sem tocar em reescanear.
- Seletor de pastas agora converte URIs `content://` do SAF em caminhos
  reais (ex.: "Download" → `/storage/emulated/0/Download`).
- Limpeza automática do cache de extrações com mais de 7 dias.
- Testes unitários da detecção/extração de zips (test/zip_rom_test.dart).

## [1.0.0] - 2026-08-05

### Adicionado
- App Flutter com tema gamer/neon (cards 3D com tilt, grid synthwave animado,
  fontes Audiowide + Rajdhani sob OFL).
- Agregador com 17 consoles no catálogo (12 prontos, 2 experimentais, 3 "em breve").
- Emulação real via núcleos libretro oficiais embutidos no APK (ponte JNI/C++
  própria: vídeo RGBA, áudio PCM, entrada joypad, save states e SRAM).
- Controles virtuais multitoque na tela + gamepads físicos Bluetooth/USB.
- Biblioteca de ROMs: pastas monitoradas, varredura automática, busca e filtros.
- Importação de BIOS (PlayStation) para a pasta do sistema.
- Build no GitHub Actions com APK release por ABI como artefato baixável;
  releases automáticas em tags `v*`.
- Guia completo de uso via Termux (docs/TERMUX.md).

[1.2.0]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.2.0
[1.1.1]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.1.1
[1.1.0]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.1.0
[1.0.1]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.0.1
[1.0.0]: https://github.com/HOWCKs/PeraatMuu/releases/tag/v1.0.0
