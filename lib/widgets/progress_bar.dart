import 'package:flutter/material.dart';

class GlobalProgressBar extends StatelessWidget {
  final int totalSec;
  final int sessionsCount;

  const GlobalProgressBar({
    super.key,
    required this.totalSec,
    required this.sessionsCount,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = totalSec ~/ 60;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade800, Colors.black87],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESSO GLOBAL', style: TextStyle(fontWeight: FontWeight.black, letterSpacing: 2, color: Colors.purpleAccent, fontSize: 14)),
              Text('$sessionsCount sessões', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (totalSec / 7200).clamp(0.0, 1.0),
            backgroundColor: Colors.deepPurple.shade900,
            color: Colors.purpleAccent,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$hours h $mins min jogados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Meta: 2h', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}
