import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/console_model.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../widgets/console_card.dart';
import '../widgets/progress_bar.dart';
import 'emulator_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProgress progress = UserProgress();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProgressService.load();
    setState(() {
      progress = p;
      loading = false;
    });
  }

  void _openConsole(ConsoleModel c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmulatorScreen(console: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.shade900, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.deepPurple]),
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PERAATMUU',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.black,
                                    letterSpacing: 4,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'LAN HOUSE DE EMULADORES',
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    color: Colors.purpleAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sync, color: Colors.purpleAccent),
                            tooltip: 'Sincronizar progresso (Termux)',
                            onPressed: () async {
                              final p = await ProgressService.syncWithTermux();
                              setState(() => progress = p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Progresso sincronizado com Termux'), backgroundColor: Colors.deepPurple),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progresso global
                  SliverToBoxAdapter(
                    child: GlobalProgressBar(
                      totalSec: progress.totalTimeSec,
                      sessionsCount: progress.sessions.length,
                    ),
                  ),

                  // Seção de consoles
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                      child: Text(
                        'CONSOLES DISPONÍVEIS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.black,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final c = ConsoleModel.consoles[i];
                        final timeSec = progress.consoleTimes[c.id] ?? 0;
                        return ConsoleCard(
                          console: c,
                          totalSec: timeSec,
                          onTap: () => _openConsole(c),
                        );
                      },
                      childCount: ConsoleModel.consoles.length,
                    ),
                  ),

                  // Últimas sessões
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        'ÚLTIMAS SESSÕES',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.black,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: progress.sessions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma sessão registrada ainda. Jogue para aparecer aqui!', style: TextStyle(color: Colors.white70)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: progress.sessions.length > 5 ? 5 : progress.sessions.length,
                            itemBuilder: (ctx, i) {
                              final s = progress.sessions.reversed.toList()[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  child: Text(s.consoleId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                                title: Text(s.gameName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text('${s.consoleId.toUpperCase()} • ${(s.timeSec ~/ 60)} min', style: const TextStyle(color: Colors.white70)),
                                trailing: Text(s.startTime.toString().split(' ').first, style: const TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                              );
                            },
                          ),
                  ),

                  // Espaço inferior + info Termux
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Gerenciado por Termux • Atualizações via GitHub Actions',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
