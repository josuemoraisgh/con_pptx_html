import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Exibida quando nenhum PPTX foi embutido no app durante a compilação.
/// Instrui o usuário sobre o fluxo correto de uso.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(),
                const SizedBox(height: 48),
                _StepsCard(),
                const SizedBox(height: 32),
                _CommandBox(
                  label: 'Windows (PowerShell)',
                  command:
                      r'.\scripts\prepare_pptx.ps1 -PptxPath "sua_aula.pptx" -Build',
                ),
                const SizedBox(height: 16),
                _CommandBox(
                  label: 'Linux / macOS (bash)',
                  command:
                      'bash scripts/prepare_pptx.sh "sua_aula.pptx" --build',
                ),
                const SizedBox(height: 32),
                const Text(
                  'Após a compilação, o site gerado em build/web/ contém seus slides\npronto para hospedar no GitHub Pages — sem servidor, sem runtime.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C6AF7), Color(0xFF4FC3F7)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.slideshow, size: 36, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'PPTX → Web',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Apresentações PowerPoint no browser, hospedadas no GitHub Pages',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C6AF7).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como usar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _Step(n: 1, text: 'Copie seu arquivo .pptx para a pasta do projeto'),
          _Step(n: 2, text: 'Execute o script de preparação (abaixo)'),
          _Step(
            n: 3,
            text:
                'O script copia o .pptx para assets/ e chama flutter build web --wasm',
          ),
          _Step(
            n: 4,
            text: 'Publique a pasta build/web/ no GitHub Pages',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  final bool last;

  const _Step({required this.n, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF7C6AF7),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  final String label;
  final String command;

  const _CommandBox({required this.label, required this.command});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  command,
                  style: const TextStyle(
                    color: Color(0xFF7CF7A0),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Colors.white38),
                tooltip: 'Copiar',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: command));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copiado!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
