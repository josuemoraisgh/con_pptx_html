# Questões em Slides — Schema v3

Este projeto detecta questões embutidas em slides PPTX de três formas,
em ordem de prioridade:

1. **XML Moodle** — bloco `<quiz>…</quiz>` no texto do slide.
2. **JSON schema v3** — JSON com `"v": 3` e `"html"` no texto do slide.
3. **Texto livre** — linhas com `Questão:`, opções `A)`, `Gabarito:`.

---

## Formato JSON v3 (recomendado para questões avançadas)

Cole diretamente no texto de qualquer shape do slide.

### Campos obrigatórios

| Chave | Tipo | Descrição |
|---|---|---|
| `v` | int | Sempre `3`. |
| `slot` | int | Posição da questão (começa em 1). |
| `page` | int | Página (começa em 0). |
| `type` | string | Tipo Moodle (ver tabela ao final). |
| `html` | string | Enunciado em HTML. |
| `input` | string | Nome do campo de formulário (ex.: `q_slide:1_answer`). |
| `seq` | string | Sequencecheck (ex.: `seq-1`). |

### Campos opcionais comuns

| Chave | Tipo | Quando usar |
|---|---|---|
| `feedback` | string | Feedback exibido após resposta. |
| `answer_html` | string | HTML da resposta correta. |
| `images` | string[] | URLs de imagens do enunciado. |

---

## Exemplos por tipo

### Múltipla escolha

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "multichoice",
  "html": "<p>Qual a capital do Brasil?</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "feedback": "Brasília é a capital federal desde 1960.",
  "answer_html": "<p>Brasília</p>",
  "choices": [
    { "v": "0", "h": "<p>São Paulo</p>",      "ok": false },
    { "v": "1", "h": "<p>Brasília</p>",       "ok": true  },
    { "v": "2", "h": "<p>Rio de Janeiro</p>", "ok": false }
  ]
}
```

### Verdadeiro ou Falso

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "truefalse",
  "html": "<p>A Terra é plana.</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "answer_html": "<p>Falso</p>",
  "choices": [
    { "v": "0", "h": "<p>Falso</p>",     "ok": true  },
    { "v": "1", "h": "<p>Verdadeiro</p>","ok": false }
  ]
}
```

### Numérica

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "numerical",
  "html": "<p>Quanto é 2 + 2?</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "answer_html": "<p>4</p>",
  "answer_field": "q_slide:1_answer"
}
```

### Resposta curta

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "shortanswer",
  "html": "<p>Qual o símbolo químico do ouro?</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "answer_html": "<p>Au</p>",
  "answer_field": "q_slide:1_answer"
}
```

### Dissertativa

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "essay",
  "html": "<p>Explique a fotossíntese em até 3 linhas.</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "answer_field": "q_slide:1_answer"
}
```

### Associação (match)

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "match",
  "html": "<p>Associe cada país à sua capital:</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "match": {
    "subs": [
      { "h": "<p>Brasil</p>",    "name": "q_slide:1_sub0", "correct": "1" },
      { "h": "<p>Argentina</p>", "name": "q_slide:1_sub1", "correct": "2" },
      { "h": "<p>Chile</p>",     "name": "q_slide:1_sub2", "correct": "3" }
    ],
    "opts": [
      { "v": "1", "h": "<p>Brasília</p>",    "ok": false },
      { "v": "2", "h": "<p>Buenos Aires</p>","ok": false },
      { "v": "3", "h": "<p>Santiago</p>",    "ok": false }
    ]
  }
}
```

### Lacunas — opções iguais em todas (gapselect / ddwtos)

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "gapselect",
  "html": "<p>O [[1]] é o astro-rei. A [[2]] é o satélite natural.</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "gap": {
    "count": 2,
    "prefix": "q_slide:1_p",
    "opts": [
      { "v": "1", "h": "<p>Sol</p>",   "ok": true  },
      { "v": "2", "h": "<p>Lua</p>",   "ok": true  },
      { "v": "3", "h": "<p>Marte</p>", "ok": false }
    ]
  }
}
```

### Lacunas — opções diferentes por lacuna

```json
"gap": {
  "count": 2,
  "prefix": "q_slide:1_p",
  "opts": [],
  "by_gap": [
    [ { "v": "1", "h": "<p>Sol</p>",  "ok": true  }, { "v": "2", "h": "<p>Lua</p>",  "ok": false } ],
    [ { "v": "1", "h": "<p>Lua</p>",  "ok": true  }, { "v": "2", "h": "<p>Sol</p>",  "ok": false } ]
  ]
}
```

### Ordenação

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "ordering",
  "html": "<p>Ordene os passos do método científico:</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "controls": [
    { "name": "q_slide:1_i0", "type": "select", "hl": "<p>Observação</p>",
      "opts": [{"v":"1","h":"1°","ok":false},{"v":"2","h":"2°","ok":false},{"v":"3","h":"3°","ok":false}] },
    { "name": "q_slide:1_i1", "type": "select", "hl": "<p>Hipótese</p>",
      "opts": [{"v":"1","h":"1°","ok":false},{"v":"2","h":"2°","ok":false},{"v":"3","h":"3°","ok":false}] },
    { "name": "q_slide:1_i2", "type": "select", "hl": "<p>Experimento</p>",
      "opts": [{"v":"1","h":"1°","ok":false},{"v":"2","h":"2°","ok":false},{"v":"3","h":"3°","ok":false}] }
  ]
}
```

### Cloze (multianswer)

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "multianswer",
  "html": "<p>A água ferve a ___ °C e congela a ___ °C.</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "controls": [
    { "name": "q_slide:1_1_answer", "type": "text",   "hl": "<p>1ª resposta</p>" },
    { "name": "q_slide:1_2_answer", "type": "number", "hl": "<p>2ª resposta</p>" }
  ]
}
```

### Arrastar e soltar em imagem (ddmarker)

```json
{
  "v": 3, "slot": 1, "page": 0,
  "type": "ddmarker",
  "html": "<p>Marque as capitais no mapa:</p>",
  "input": "q_slide:1_answer",
  "seq": "seq-1",
  "images": ["https://exemplo.com/mapa.png"],
  "dd": {
    "bg": "https://exemplo.com/mapa.png",
    "choices": [
      { "no": 1, "name": "q_slide:1_c1", "h": "Brasília", "inf": false, "n": 1 },
      { "no": 2, "name": "q_slide:1_c2", "h": "Lima",     "inf": false, "n": 1 }
    ]
  }
}
```

---

## Referência rápida de chaves curtas

| Chave | Significado completo |
|---|---|
| `v` em choice/opts | `value` — identificador enviado ao servidor |
| `h` em choice/opts/sub | `html` — HTML exibido ao aluno |
| `ok` | `isCorrect` |
| `hl` | `htmlLabel` — rótulo HTML do controle |
| `opts` | `options` |
| `subs` | `subQuestions` |
| `correct` | `correctValue` — valor de `v` da opção correta |
| `prefix` | `inputNamePrefix` |
| `by_gap` | opções por lacuna (só quando diferem) |
| `bg` | `backgroundImageUrl` |
| `inf` | `infinite` |
| `n` | `noOfDrags` |

---

## Convenção de nomes de campo para slides

Use o padrão `q_slide:{slot}_answer` para o campo `input`.  
Para controles internos: `q_slide:{slot}_sub{i}`, `q_slide:{slot}_p{n}`, `q_slide:{slot}_i{i}`, etc.

---

## Tipos Moodle suportados

| `type` | Campo extra |
|---|---|
| `multichoice` | `choices` |
| `truefalse` | `choices` (2 itens) |
| `calculatedmulti` | `choices` |
| `numerical` / `calculated` / `calculatedsimple` | `answer_field` |
| `shortanswer` | `answer_field` |
| `essay` | `answer_field` |
| `match` | `match` |
| `gapselect` / `ddwtos` | `gap` |
| `ordering` / `multianswer` | `controls` |
| `ddmarker` / `ddimageortext` | `dd` |

---

## Dica: gerar o JSON a partir do Dart

```dart
import 'package:moodle_quiz_dep/core/utils/question_serializer.dart';

// Se já tiver um QuestionEntity:
final jsonStr = QuestionSerializer.encode(question);
// Cole o jsonStr no slide.
```
