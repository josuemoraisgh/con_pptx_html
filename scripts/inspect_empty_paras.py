import zipfile, xml.etree.ElementTree as ET

ns = {
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'p': 'http://schemas.openxmlformats.org/presentationml/2006/main',
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

        if sp_name not in ('SafetyCard',):
            continue

        print(f'\n=== Shape: {sp_name} (empty paragraphs) ===')

        for i, para in enumerate(txBody.findall('a:p', ns)):
            text = ''.join(t.text or '' for t in para.findall('.//a:t', ns))
            if text.strip():
                continue  # skip non-empty
            
            pPr = para.find('a:pPr', ns)
            attrs = dict(pPr.attrib) if pPr is not None else {}
            
            # defRPr in pPr
            defRPr = pPr.find('a:defRPr', ns) if pPr is not None else None
            defSz = defRPr.get('sz', 'NONE') if defRPr is not None else 'no defRPr'
            
            # runs (even empty ones)
            runs = para.findall('a:r', ns)
            run_szs = []
            for r in runs:
                rPr = r.find('a:rPr', ns)
                if rPr is not None:
                    run_szs.append(rPr.get('sz', 'no sz'))
            
            # endParaRPr
            endParaRPr = para.find('a:endParaRPr', ns)
            endSz = endParaRPr.get('sz', 'NONE') if endParaRPr is not None else 'no endParaRPr'
            
            print(f'  p[{i}]: attrs={attrs} defSz={defSz} endSz={endSz} numRuns={len(runs)} runSzs={run_szs}')
            
            # Full XML of paragraph
            print(f'    XML: {ET.tostring(para, encoding="unicode")[:200]}')
            print()
