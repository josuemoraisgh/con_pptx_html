import zipfile, xml.etree.ElementTree as ET

ns = {
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'p': 'http://schemas.openxmlformats.org/presentationml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
}

with zipfile.ZipFile('assets/presentation.pptx') as z:
    tree = ET.parse(z.open('ppt/slides/slide15.xml'))
    root = tree.getroot()

    for sp_idx, sp in enumerate(root.findall('.//p:sp', ns)):
        txBody = sp.find('.//p:txBody', ns)
        if txBody is None:
            continue

        cNvPr = sp.find('.//p:nvSpPr/p:cNvPr', ns)
        sp_name = cNvPr.get('name', '?') if cNvPr is not None else '?'

        # Get txBody defaults (lstStyle, bodyPr)
        bodyPr = txBody.find('a:bodyPr', ns)
        lstStyle = txBody.find('a:lstStyle', ns)

        print(f'\n=== Shape {sp_idx}: {sp_name} ===')

        for i, para in enumerate(txBody.findall('a:p', ns)):
            pPr = para.find('a:pPr', ns)
            lvl = pPr.get('lvl', '0') if pPr is not None else '0'
            marL = pPr.get('marL', '') if pPr is not None else ''
            indent = pPr.get('indent', '') if pPr is not None else ''

            # Look for default run props (pPr/defRPr)
            defRPr = pPr.find('a:defRPr', ns) if pPr is not None else None
            defSz = defRPr.get('sz', '') if defRPr is not None else ''

            # Get first run
            first_rPr = para.find('.//a:rPr', ns)
            sz = first_rPr.get('sz', '') if first_rPr is not None else ''
            baseline = first_rPr.get('baseline', '') if first_rPr is not None else ''

            text = ''.join(t.text or '' for t in para.findall('.//a:t', ns))
            if text.strip():
                print(f'  p[{i}] lvl={lvl} marL={marL} indent={indent} sz={sz} defSz={defSz} baseline={baseline} | {text[:50]}')
