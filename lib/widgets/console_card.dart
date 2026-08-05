import 'package:flutter/material.dart';
import '../models/console_model.dart';

class ConsoleCard extends StatelessWidget {
  final ConsoleModel console;
  final VoidCallback? onTap;
  final int totalSec; // progresso no console

  const ConsoleCard({
    super.key,
    required this.console,
    this.onTap,
    this.totalSec = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = console.isAvailable;

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black87,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header com imagem de fundo simulada
              SizedBox(
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      console.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.deepPurple.shade800,
                        child: const Center(
                          child: Icon(
                            Icons.sports_esports,
                            size: 48,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.greenAccent.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          isActive ? 'ATIVO' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            console.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.black,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Text(
                          console.manufacturer,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      console.fullName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      console.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Barra de progresso local
                    if (totalSec > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Seu progresso', style: TextStyle(fontSize: 11, color: Colors.purpleAccent)),
                              Text('${(totalSec ~/ 60)} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (totalSec / 3600).clamp(0.0, 1.0),
                            backgroundColor: Colors.deepPurple.shade900,
                            color: Colors.purpleAccent,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.videogame_asset, size: 16, color: Colors.purpleAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Controles: ${console.maxControllers}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botão inferior
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.purpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  border: Border(top: BorderSide(color: Colors.purpleAccent.withOpacity(0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive ? 'JOGAR' : 'INDISPONÍVEL',
                      style: TextStyle(
                        fontWeight: FontWeight.black,
                        letterSpacing: 2,
                        color: isActive ? Colors.purpleAccent : Colors.white54,
                      ),
                    ),
                    Icon(
                      isActive ? Icons.arrow_forward : Icons.block,
                      color: isActive ? Colors.purpleAccent : Colors.white54,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
