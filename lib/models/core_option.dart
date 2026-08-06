/// Opções de núcleo (core options libretro) configuráveis pelo usuário,
/// por console. Aplicadas na hora de abrir o jogo (o núcleo pergunta o
/// valor de cada chave durante o carregamento).
library;

/// Uma escolha possível de uma opção.
class CoreOptionChoice {
  final String value;

  /// Rótulo curto exibido no chip.
  final String label;

  /// Descrição opcional (tooltip/legenda).
  final String? hint;

  const CoreOptionChoice(this.value, this.label, {this.hint});
}

/// Definição de uma opção de núcleo exposta na interface.
class CoreOptionDef {
  /// Chave libretro exata (ex.: `parallel-n64-screensize`).
  final String key;

  final String title;

  /// Texto de ajuda exibido abaixo do título.
  final String? subtitle;

  final List<CoreOptionChoice> choices;

  /// Valor padrão quando o usuário nunca mexeu.
  final String defaultValue;

  const CoreOptionDef({
    required this.key,
    required this.title,
    required this.choices,
    required this.defaultValue,
    this.subtitle,
  });

  CoreOptionChoice choiceOf(String value) =>
      choices.firstWhere((c) => c.value == value, orElse: () => choices.first);
}

/// Catálogo: console -> opções disponíveis. Chaves desconhecidas pelo
/// núcleo são simplesmente ignoradas (o núcleo usa o padrão interno).
const Map<String, List<CoreOptionDef>> kCoreOptionDefsBySystem = {
  'n64': [
    CoreOptionDef(
      key: 'parallel-n64-screensize',
      title: 'Resolução interna de render',
      subtitle:
          'Acima de 2x exige muito da CPU. Neste aparelho (2 GB), em 2x+ '
          'o jogo perde velocidade e o áudio pode falhar — use 1x–2x.',
      defaultValue: '320x240',
      choices: [
        CoreOptionChoice('320x240', '1x (nativa)', hint: 'mais rápido'),
        CoreOptionChoice('640x480', '2x'),
        CoreOptionChoice('960x720', '3x'),
        CoreOptionChoice('1280x960', '4x'),
        CoreOptionChoice('1600x1200', '5x', hint: 'só aparelhos fortes'),
      ],
    ),
    CoreOptionDef(
      key: 'parallel-n64-angrylion-multithreading',
      title: 'Render em vários núcleos da CPU',
      subtitle: 'Divide o rasterizador software em threads. Deixe LIGADO.',
      defaultValue: 'enabled',
      choices: [
        CoreOptionChoice('enabled', 'Ligado'),
        CoreOptionChoice('disabled', 'Desligado'),
      ],
    ),
    CoreOptionDef(
      key: 'parallel-n64-angrylion-vioverlay',
      title: 'Filtro de vídeo (VI)',
      subtitle: 'Suaviza a imagem final imitando o vídeo-composto do N64.',
      defaultValue: 'Filtered',
      choices: [
        CoreOptionChoice('Filtered', 'Suave'),
        CoreOptionChoice('Unfiltered', 'Nítido'),
        CoreOptionChoice('ForceDisable', 'Desligado'),
      ],
    ),
    CoreOptionDef(
      key: 'parallel-n64-aspectratiohint',
      title: 'Proporção de tela',
      subtitle: 'Tela cheia esticada (16:9) — hack, pode dar defeitos '
          'gráficos em alguns jogos.',
      defaultValue: 'normal',
      choices: [
        CoreOptionChoice('normal', 'Original (4:3)'),
        CoreOptionChoice('widescreen', 'Esticar 16:9'),
      ],
    ),
  ],
  'psp': [
    CoreOptionDef(
      key: 'ppsspp_internal_resolution',
      title: 'Resolução interna de render',
      subtitle: 'Renderiza o 3D do PSP mais nítido. Em aparelhos de '
          '2 GB de RAM, 1x–2x é o limite confortável.',
      defaultValue: '480x272',
      choices: [
        CoreOptionChoice('480x272', '1x (nativa)', hint: 'mais rápido'),
        CoreOptionChoice('960x544', '2x'),
        CoreOptionChoice('1440x816', '3x'),
        CoreOptionChoice('1920x1088', '4x', hint: 'só aparelhos fortes'),
      ],
    ),
  ],
};

/// Opções definidas para um console (lista vazia = núcleo só com padrões).
List<CoreOptionDef> coreOptionDefsFor(String systemId) =>
    kCoreOptionDefsBySystem[systemId] ?? const [];
