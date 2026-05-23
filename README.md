# con_pptx_html

A new Flutter project.

## Comparacao Visual Automatica (Slide a Slide)

Use o script abaixo para comparar o render atual do app contra imagens de
referencia e gerar relatorio por area de diferenca.

### 1) Estrutura esperada

- Pasta com imagens renderizadas do app (ex.: PNG por slide)
- Pasta com imagens de referencia (mesmo nome ou mesmo numero de slide)

Exemplos de pareamento valido:
- slide_001.png <-> slide_001.png
- atual_2.png <-> referencia_2.png

### 2) Executar

```bash
dart run scripts/visual_diff.dart \
	--actual-dir artifacts/render_atual \
	--reference-dir artifacts/referencia \
	--output-dir artifacts/visual_diff \
	--threshold 24 \
	--min-area 30
```

### 3) Saida

- report.json: metricas completas por slide
- report.md: resumo legivel com ranking de severidade
- masks/*.png: mascara binaria da diferenca
- overlays/*.png: diferencas em vermelho com caixas por area

### 4) Parametros uteis

- --threshold: sensibilidade do pixel (0-255), padrao 24
- --min-area: area minima em pixels para reportar regiao, padrao 30
- --max-slides: limita quantos slides comparar

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
