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

        print(f'\n=== Shape {sp_idx}: {sp_name} ===')

        for i, para in enumerate(txBody.findall('a:p', ns)):
            pPr = para.find('a:pPr', ns)
            if pPr is None:
                continue
            
            # Line spacing
            lnSpc = pPr.find('a:lnSpc', ns)
            spcBef = pPr.find('a:spcBef', ns)
            spcAft = pPr.find('a:spcAft', ns)
            
            if lnSpc is not None or spcBef is not None or spcAft is not None:
                lnSpc_val = ''
                if lnSpc is not None:
                    spcPct = lnSpc.find('a:spcPct', ns)
                    spcPts = lnSpc.find('a:spcPts', ns)
                    if spcPct is not None:
                        lnSpc_val = f'pct={spcPct.get("val","")}' 
                    elif spcPts is not None:
                        lnSpc_val = f'pts={spcPts.get("val","")}'
                
                spcBef_val = ''
                if spcBef is not None:
                    spcPct = spcBef.find('a:spcPct', ns)
                    spcPts = spcBef.find('a:spcPts', ns)
                    if spcPct is not None:
                        spcBef_val = f'pct={spcPct.get("val","")}'
                    elif spcPts is not None:
                        spcBef_val = f'pts={spcPts.get("val","")}'
                
                spcAft_val = ''
                if spcAft is not None:
                    spcPct = spcAft.find('a:spcPct', ns)
                    spcPts = spcAft.find('a:spcPts', ns)
                    if spcPct is not None:
                        spcAft_val = f'pct={spcPct.get("val","")}'
                    elif spcPts is not None:
                        spcAft_val = f'pts={spcPts.get("val","")}'
                
                text = ''.join(t.text or '' for t in para.findall('.//a:t', ns))
                if text.strip():
                    print(f'  p[{i}] lnSpc={lnSpc_val} spcBef={spcBef_val} spcAft={spcAft_val} | {text[:40]}')
