# con_pptx_html

Conversor de apresentacoes PowerPoint (.pptx) para Web usando Flutter WASM.

## Gerar o site com um PPTX novo

Nao use apenas `flutter build web --wasm` depois de trocar o PPTX. Esse
comando compila o Flutter, mas nao regenera os dados embutidos da apresentacao.

Use um destes comandos:

```powershell
.\scripts\build_web_pptx.ps1
```

Ou passando outro PPTX:

```powershell
.\scripts\build_web_pptx.ps1 "C:\caminho\aula.pptx"
```

Tambem funciona via `.cmd`:

```powershell
.\scripts\build_web_pptx.cmd "C:\caminho\aula.pptx"
```

Alternativa usando a ferramenta Dart:

```powershell
dart run tool/build_web.dart assets/presentation.pptx
```

Ou, para copiar outro arquivo para `assets/presentation.pptx`, regenerar os
dados e gerar `build/web`:

```powershell
.\scripts\prepare_pptx.ps1 -PptxPath "C:\caminho\aula.pptx" -Build
```

Se quiser apenas regenerar os dados depois de substituir
`assets/presentation.pptx` manualmente:

```powershell
$env:PPTX_INPUT='assets/presentation.pptx'
flutter test tool/compile_pptx.dart
flutter build web --wasm
Remove-Item Env:\PPTX_INPUT
```

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
