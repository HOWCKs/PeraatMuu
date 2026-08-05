import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../state/app_settings.dart';
import '../../state/core_controller.dart';
import '../../state/library_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/library_actions.dart';
import '../widgets/section_header.dart';

/// Ajustes: pastas de ROMs, BIOS, núcleos, controles e informações do app.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final cores = context.watch<CoreController>();
    final settings = context.watch<AppSettings>();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text('AJUSTES', style: AppTheme.display(18, letterSpacing: 4)),
        ),

        // ---------------- Armazenamento ----------------
        const SectionHeader(title: 'Pastas de ROMs'),
        _Card(
          child: Column(
            children: [
              if (library.folders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhuma pasta monitorada ainda.',
                    style: TextStyle(color: AppTheme.textMid),
                  ),
                )
              else
                ...library.folders.map(
                  (folder) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_rounded,
                        color: AppTheme.neon, size: 20),
                    title: Text(
                      folder,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textHigh),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: AppTheme.textMid, size: 20),
                      onPressed: () => library.removeFolder(folder),
                    ),
                  ),
                ),
              const Divider(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.create_new_folder_rounded,
                      label: 'ADICIONAR',
                      onTap: () => addRomsFolder(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'REESCANEAR',
                      busy: library.scanning,
                      onTap: () async {
                        final found = await library.rescanAll();
                        final pruned = await library.pruneMissing();
                        if (context.mounted) {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Varredura: +$found jogos • $pruned removidos por arquivo ausente.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ---------------- BIOS ----------------
        const SectionHeader(title: 'BIOS (PlayStation e cia)'),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: AppTheme.yellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pasta do sistema',
                      style: AppTheme.display(12, letterSpacing: 1.6),
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.file_upload_rounded,
                    label: 'IMPORTAR BIOS',
                    onTap: () => _importBios(context, cores),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cores.systemDir.isEmpty
                    ? 'Pasta do sistema ainda não inicializada.'
                    : 'Copie seus arquivos de BIOS para:\n${cores.systemDir}',
                style:
                    const TextStyle(color: AppTheme.textMid, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ex.: scph5501.bin (PS1 americano). Use apenas BIOS extraída do seu próprio console.',
                style: TextStyle(color: AppTheme.textMid, fontSize: 12),
              ),
            ],
          ),
        ),

        // ---------------- Núcleos ----------------
        const SectionHeader(title: 'Núcleos de emulação'),
        _Card(
          child: Column(
            children: [
              for (final coreId in kUniqueCoreIds)
                _CoreRow(coreId: coreId, ready: cores.availability[coreId] ?? false),
              const Divider(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'VERIFICAR',
                  onTap: () => cores.refresh(),
                ),
              ),
            ],
          ),
        ),

        // ---------------- Controles ----------------
        const SectionHeader(title: 'Controles'),
        const _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.touch_app_rounded,
                text:
                    'No jogo, toque em ≡ e escolha "Controles" para arrastar botões, mudar tamanho e trocar ícones (até com imagem sua). Resposta tátil ativada.',
              ),
              SizedBox(height: 8),
              _InfoRow(
                icon: Icons.gamepad_rounded,
                text:
                    'Gamepads Bluetooth/USB são detectados automaticamente (inclui analógico).',
              ),
              SizedBox(height: 8),
              _InfoRow(
                icon: Icons.save_rounded,
                text:
                    'Salvamentos: os estados e a SRAM (save da bateria) são gravados automaticamente ao sair.',
              ),
            ],
          ),
        ),

        // ---------------- Desempenho ----------------
        const SectionHeader(title: 'Desempenho'),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeThumbColor: AppTheme.neon,
                activeTrackColor: AppTheme.neon.withValues(alpha: 0.35),
                title: const Text(
                  'Reduzir animações e efeitos',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.textHigh),
                ),
                subtitle: const Text(
                  'Desliga varreduras animadas e o tilt 3D dos cards. Recomendado.',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMid),
                ),
                value: settings.reducedEffects,
                onChanged: (v) => settings.setReducedEffects(v),
              ),
              const SizedBox(height: 8),
              const _InfoRow(
                icon: Icons.speed_rounded,
                text:
                    'Dentro do jogo: "Acelerar velocidade" (até 5×), ajustes de cor e escala de tela ficam no menu ≡.',
              ),
              const SizedBox(height: 8),
              const _InfoRow(
                icon: Icons.build_rounded,
                text:
                    'Travou com um cheat? Abra o menu ≡ > Cheats e desative — alguns códigos alteram a RAM do jogo todo quadro.',
              ),
            ],
          ),
        ),

        // ---------------- Sobre ----------------
        const SectionHeader(title: 'Sobre'),
        _Card(
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 64,
                height: 64,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_esports_rounded,
                  size: 56,
                  color: AppTheme.neon,
                ),
              ),
              const SizedBox(height: 10),
              Text('PERAATMUU', style: AppTheme.display(16, letterSpacing: 3)),
              const SizedBox(height: 4),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return Text(
                    info == null
                        ? 'Carregando versão...'
                        : 'Versão ${info.version} (${info.buildNumber})',
                    style: const TextStyle(
                        color: AppTheme.textMid, fontSize: 13),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Núcleos: projetos open-source da família libretro (Stella, Nestopia UE, Snes9x, Gambatte, mGBA, Genesis Plus GX, Beetle/Mednafen, FinalBurn Neo, PCSX ReARMed), cada um sob sua própria licença.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMid, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'O PeraatMuu não inclui nem distribui ROMs ou BIOS. Jogue apenas backups dos jogos que você possui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMid, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importBios(BuildContext context, CoreController cores) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Escolha o arquivo de BIOS',
      type: FileType.any,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    if (cores.systemDir.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Pasta do sistema indisponível.')),
      );
      return;
    }
    try {
      final source = File(path);
      final name = source.uri.pathSegments.last;
      await source.copy('${cores.systemDir}/$name');
      messenger?.showSnackBar(
        SnackBar(content: Text('BIOS copiada: $name')),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Falha ao copiar BIOS: $e')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Widgets internos
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({this.child = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF232338)),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final FutureOrVoidCallback? onTap;
  final bool busy;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : () => onTap?.call(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.neon,
                  ),
                )
              else
                Icon(icon, size: 15, color: AppTheme.neon),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Audiowide',
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    color: AppTheme.textHigh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoreRow extends StatelessWidget {
  final String coreId;
  final bool ready;

  const _CoreRow({required this.coreId, required this.ready});

  @override
  Widget build(BuildContext context) {
    final names = kConsoleCatalog
        .where((s) => s.coreId == coreId)
        .map((s) => s.shortName)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: ready ? AppTheme.neon : AppTheme.textMid,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$coreId ($names)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppTheme.textHigh),
            ),
          ),
          Text(
            ready ? 'embutido' : 'ausente',
            style: TextStyle(
              fontSize: 11,
              color: ready ? AppTheme.neon : AppTheme.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.neon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textMid, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Callback que pode ser síncrono ou assíncrono.
typedef FutureOrVoidCallback = Future<void>? Function();
