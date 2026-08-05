# 🧪 Smoke test nativo da ponte retrobridge

Valida o coração da emulação **sem precisar de Android/Flutter**: compila
`android/app/src/main/cpp/retrobridge.cpp` em host Linux (ou Termux) junto com
um **núcleo libretro fake** que gera vídeo RGB565 e áudio senoidal, e verifica:

- `dlopen` do núcleo e resolução de todos os 22 símbolos `retro_*`
- callbacks de environment (pastas de sistema/saves, pixel format)
- thread de emulação e pacing de FPS (60 fps)
- conversão de vídeo RGB565 → RGBA8888
- buffer de áudio PCM
- leitura de botões (joypad)
- save states e SRAM (round-trip com verificação de conteúdo)

## Como rodar

```bash
bash tools/native_smoke/run_smoke.sh
```

No **Termux**:

```bash
pkg install -y clang
bash tools/native_smoke/run_smoke.sh
```

Saída esperada: `== SMOKE TEST OK ==` com todos os checks em `PASS`.

## Arquivos

```
├── fakecore.cpp   # núcleo libretro mínimo (22 símbolos) para testes
├── harness.cpp    # executa o ciclo completo: init → load → run → saves
├── stubs/         # jni.h / android/log.h funcionais para host
└── run_smoke.sh   # script de build + execução
```
