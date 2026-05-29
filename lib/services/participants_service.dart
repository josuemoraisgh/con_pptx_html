import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

Future<List<String>> loadParticipantNamesFromAsset({
  String assetPath = 'assets/participants.xlsx',
}) async {
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    return extractParticipantNamesFromXlsx(bytes);
  } catch (_) {
    return const [];
  }
}

List<String> extractParticipantNamesFromXlsx(Uint8List xlsxBytes) {
  final archive = ZipDecoder().decodeBytes(xlsxBytes, verify: false);
  final files = <String, Uint8List>{
    for (final file in archive.files)
      if (file.isFile) file.name: Uint8List.fromList(file.content as List<int>),
  };

  final sharedStrings = _parseSharedStrings(files['xl/sharedStrings.xml']);
  final sheetPath =
      _resolveFirstWorksheetPath(files) ?? 'xl/worksheets/sheet1.xml';
  final sheetBytes = files[sheetPath];
  if (sheetBytes == null || sheetBytes.isEmpty) return const [];

  final sheetDoc = XmlDocument.parse(
    utf8.decode(sheetBytes, allowMalformed: true),
  );
  final names = <String>[];
  final dedup = <String>{};

  final rows = sheetDoc.findAllElements('row');
  for (final row in rows) {
    String? firstTextCell;
    var firstColumnIndex = 1 << 30;

    for (final cell in row.findElements('c')) {
      final ref = cell.getAttribute('r') ?? '';
      final colIndex = _columnIndexFromCellRef(ref);
      if (colIndex == null) continue;

      final value = _resolveCellText(cell, sharedStrings).trim();
      if (value.isEmpty) continue;

      if (colIndex < firstColumnIndex) {
        firstColumnIndex = colIndex;
        firstTextCell = value;
      }
    }

    if (firstTextCell == null) continue;
    final candidate = _normalizeName(firstTextCell);
    if (candidate.isEmpty || _looksLikeHeader(candidate)) continue;

    final key = candidate.toLowerCase();
    if (dedup.add(key)) {
      names.add(candidate);
    }
  }

  return names;
}

List<String> _parseSharedStrings(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return const [];

  final doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
  return doc
      .findAllElements('si')
      .map((si) => si.findAllElements('t').map((t) => t.innerText).join())
      .toList();
}

String? _resolveFirstWorksheetPath(Map<String, Uint8List> files) {
  final workbookBytes = files['xl/workbook.xml'];
  final relsBytes = files['xl/_rels/workbook.xml.rels'];
  if (workbookBytes == null || relsBytes == null) return null;

  final workbook = XmlDocument.parse(
    utf8.decode(workbookBytes, allowMalformed: true),
  );
  final rels = XmlDocument.parse(utf8.decode(relsBytes, allowMalformed: true));

  final firstSheet = workbook.findAllElements('sheet').firstOrNull;
  if (firstSheet == null) return null;

  final rid = firstSheet.attributes
      .where((a) => a.localName == 'id')
      .map((a) => a.value)
      .firstOrNull;
  if (rid == null || rid.isEmpty) return null;

  final target = rels
      .findAllElements('Relationship')
      .where((rel) => rel.getAttribute('Id') == rid)
      .map((rel) => rel.getAttribute('Target'))
      .whereType<String>()
      .firstOrNull;
  if (target == null || target.isEmpty) return null;

  return target.startsWith('xl/')
      ? target
      : target.startsWith('/')
      ? target.substring(1)
      : 'xl/$target';
}

int? _columnIndexFromCellRef(String ref) {
  final match = RegExp(r'([A-Za-z]+)').firstMatch(ref);
  final letters = match?.group(1);
  if (letters == null || letters.isEmpty) return null;

  var index = 0;
  for (final codeUnit in letters.toUpperCase().codeUnits) {
    index = index * 26 + (codeUnit - 64);
  }
  return index;
}

String _resolveCellText(XmlElement cell, List<String> sharedStrings) {
  final type = cell.getAttribute('t')?.toLowerCase();

  if (type == 'inlineStr'.toLowerCase()) {
    return cell
        .findAllElements('is')
        .expand((isNode) => isNode.findAllElements('t'))
        .map((t) => t.innerText)
        .join();
  }

  final rawValue = cell.findElements('v').firstOrNull?.innerText ?? '';
  if (rawValue.isEmpty) return '';

  if (type == 's') {
    final index = int.tryParse(rawValue);
    if (index == null || index < 0 || index >= sharedStrings.length) return '';
    return sharedStrings[index];
  }

  return rawValue;
}

String _normalizeName(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _looksLikeHeader(String value) {
  final v = value.toLowerCase();
  const headers = {
    'nome',
    'nomes',
    'aluno',
    'alunos',
    'name',
    'names',
    'student',
    'students',
    'participante',
    'participantes',
  };

  if (headers.contains(v)) return true;
  return RegExp(r'^[0-9]+$').hasMatch(v);
}
