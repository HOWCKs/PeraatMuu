import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/console_system.dart';
import '../../services/bios_files.dart';
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
        const SectionHeader(title: 'BIOS (PlayStation)'),
        _BiosCard(systemDir: cores.systemDir),
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
              const SizedBox(height: 8),
              const Text(
                'Fotos dos consoles: Wikimedia Commons (Evan-Amos e outros autores, CC) e fontes públicas — usadas só para identificar os produtos. Nintendo, Sega, Sony, Atari, SNK e Bandai são marcas de seus donos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMid, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets internos
// ---------------------------------------------------------------------------

/// Card de BIOS: lista para PS1 e Nintendo DS quais arquivos já estão
/// na pasta do sistema e permite importar vários de uma vez (nomes de
/// dumps comuns como biosnds9.bin são normalizados automaticamente).
class _BiosCard extends StatefulWidget {
  final String systemDir;

  const _BiosCard({required this.systemDir});

  @override
  State<_BiosCard> createState() => _BiosCardState();
}

class _BiosCardState extends State<_BiosCard> {
  bool _exists(String name) =>
      widget.systemDir.isNotEmpty && File('${widget.systemDir}/$name').existsSync();

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (widget.systemDir.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Pasta do sistema indisponível.')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Escolha um ou mais arquivos de BIOS',
      type: FileType.any,
      allowMultiple: true,
    );
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;

    var copied = 0;
    final unrecognized = <String>[];
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final source = File(path);
        final original = source.uri.pathSegments.last;
        final canonical = canonicalBiosName(original);
        // Nomes desconhecidos vão em minúsculas mesmo assim — o usuário
        // pode estar importando uma variante válida de outro núcleo.
        final dest = canonical ?? original.toLowerCase();
        await source.copy('${widget.systemDir}/$dest');
        if (canonical != null) copied++;
        if (canonical == null) unrecognized.add(original);
      } catch (e) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Falha ao copiar BIOS: $e')),
        );
      }
    }
    if (!mounted) return;
    setState(() {}); // atualiza os status da lista
    if (copied > 0) {
      messenger?.showSnackBar(
        SnackBar(content: Text('BIOS importada: $copied arquivo(s).')),
      );
    }
    if (unrecognized.isNotEmpty) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Nome não reconhecido: ${unrecognized.join(', ')}. '
              'Copiado mesmo assim em minúsculas.'),
        ),
      );
    }
  }

  Widget _fileRow(String name, {String? note}) {
    final ok = _exists(name);
    final kb = kBiosExpectedKb[name];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: ok ? AppTheme.neon : AppTheme.textMid,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kb != null ? '$name  (${kb} KB)' : name,
              style: TextStyle(
                color: ok ? AppTheme.textHigh : AppTheme.textMid,
                fontSize: 12.5,
              ),
            ),
          ),
          if (note != null)
            Text(note,
                style: const TextStyle(color: AppTheme.textMid, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ps1Ok = requiredBiosFilesFor('ps1').any(_exists);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppTheme.yellow, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Pasta do sistema',
                    style: AppTheme.display(12, letterSpacing: 1.6)),
              ),
              _ActionButton(
                icon: Icons.file_upload_rounded,
                label: 'IMPORTAR',
                onTap: _import,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.systemDir.isEmpty
                ? 'Pasta do sistema ainda não inicializada.'
                : 'Arquivos em:\\n${widget.systemDir}',
            style: const TextStyle(color: AppTheme.textMid, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Text('PLAYSTATION (PS1)',
              style: AppTheme.display(10.5, letterSpacing: 1.2,
                  color: ps1Ok ? AppTheme.neon : AppTheme.textMid)),
          const SizedBox(height: 4),
          for (final f in requiredBiosFilesFor('ps1')) _fileRow(f),
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Text(
              'PS1 funciona com BIOS interna simulada; a real melhora a compatibilidade (basta UMA).',
              style: TextStyle(color: AppTheme.textMid, fontSize: 11),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nintendo DS (DeSmuME) e PS2 (Play!) NÃO precisam de BIOS. '
            'GameCube/Wii já trazem os dados de sistema embutidos no app.',
            style: TextStyle(color: AppTheme.textMid, fontSize: 11),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use apenas BIOS extraída do seu próprio console. Nomes em '
            'MAIÚSCULAS são normalizados na importação.',
            style: TextStyle(color: AppTheme.textMid, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

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
