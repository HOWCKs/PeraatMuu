import 'package:flutter/material.dart';
import 'dart:async';
import '../models/console_model.dart';
import '../services/ffi_bridge.dart';
import '../services/progress_service.dart';
import '../models/progress_model.dart';

class EmulatorScreen extends StatefulWidget {
  final ConsoleModel console;
  const EmulatorScreen({super.key, required this.console});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> {
  bool running = false;
  bool loaded = false;
  int timerSec = 0;
  Timer? timer;
  String status = 'INICIANDO EMULADOR';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => status = 'CARREGANDO LIB NATIVA...');
    await Future.delayed(const Duration(milliseconds: 600));
    final ok = FfiBridge.loadLib(widget.console.nativeLibName);
    setState(() {
      loaded = ok;
      status = ok ? 'PRONTO — ROM CARREGADO' : 'ERRO: LIB NÃO ENCONTRADA';
    });
  }

  void _startGame() {
    if (!loaded) return;
    setState(() {
      running = true;
      status = 'JOGANDO...';
    });
    FfiBridge.initEmulator(widget.console.nativeLibName, '/assets/roms/demo.rom');
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => timerSec++);
    });
  }

  void _stopGame() async {
    timer?.cancel();
    setState(() {
      running = false;
      status = 'FINALIZADO';
    });
    FfiBridge.shutdown(widget.console.nativeLibName);
    await ProgressService.addSession(SessionModel(
      consoleId: widget.console.id,
      gameName: 'Jogo emulado',
      timeSec: timerSec,
      startTime: DateTime.now().subtract(Duration(seconds: timerSec)),
    ));
  }

  @override
  void dispose() {
    timer?.cancel();
    if (running) _stopGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.deepPurple.shade900,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (running) _stopGame();
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      widget.console.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.black,
                        fontSize: 18,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Área de renderização
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade900, Colors.black],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        running ? Icons.sports_esports : Icons.videogame_asset,
                        size: 80,
                        color: running ? Colors.purpleAccent : Colors.white30,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (running)
                        Text(
                          '${timerSec ~/ 60}:${(timerSec % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.black,
                            color: Colors.purpleAccent,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (!running && loaded)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('INICIAR JOGO', style: TextStyle(fontWeight: FontWeight.black)),
                          onPressed: _startGame,
                        ),
                      if (running)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          icon: const Icon(Icons.stop),
                          label: const Text('ENCERRAR SESSION', style: TextStyle(fontWeight: FontWeight.black)),
                          onPressed: _stopGame,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Controles virtuais
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CtrlBtn(icon: Icons.arrow_upward, label: 'UP'),
                  Column(
                    children: [
                      _CtrlBtn(icon: Icons.arrow_back, label: 'L'),
                      const SizedBox(height: 4),
                      _CtrlBtn(icon: Icons.arrow_forward, label: 'R'),
                    ],
                  ),
                  _CtrlBtn(icon: Icons.arrow_downward, label: 'DN'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CtrlBtn(icon: Icons.circle, label: 'A'),
                  _CtrlBtn(icon: Icons.square, label: 'B'),
                  _CtrlBtn(icon: Icons.access_time, label: 'START'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CtrlBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.purpleAccent.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.purpleAccent, size: 24),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
