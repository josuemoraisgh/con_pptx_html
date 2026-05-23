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

        if sp_name not in ('SafetyCard', 'EvoCard'):
            continue

        print(f'\n=== Shape: {sp_name} ===')

        for i, para in enumerate(txBody.findall('a:p', ns)):
            pPr = para.find('a:pPr', ns)
            
            # Full pPr attributes
            attrs = dict(pPr.attrib) if pPr is not None else {}
            
            # Line spacing
            lnSpc_val = ''
            spcBef_val = ''
            spcAft_val = ''
            if pPr is not None:
                lnSpc = pPr.find('a:lnSpc', ns)
                spcBef = pPr.find('a:spcBef', ns)
                spcAft = pPr.find('a:spcAft', ns)
                if lnSpc is not None:
                    for child in lnSpc:
                        tag = child.tag.split('}')[1]
                        lnSpc_val = f'{tag}={child.get("val","")}'
                if spcBef is not None:
                    for child in spcBef:
                        tag = child.tag.split('}')[1]
                        spcBef_val = f'{tag}={child.get("val","")}'
                if spcAft is not None:
                    for child in spcAft:
                        tag = child.tag.split('}')[1]
                        spcAft_val = f'{tag}={child.get("val","")}'
            
            # Bullet
            buChar = pPr.find('a:buChar', ns) if pPr is not None else None
            buFont = pPr.find('a:buFont', ns) if pPr is not None else None
            buNone = pPr.find('a:buNone', ns) if pPr is not None else None
            buSzPct = pPr.find('a:buSzPct', ns) if pPr is not None else None
            buClr = pPr.find('.//a:buClr', ns) if pPr is not None else None
            
            bu_char = buChar.get('char', '') if buChar is not None else ''
            bu_font = buFont.get('typeface', '') if buFont is not None else ''
            bu_none = buNone is not None
            bu_sz = buSzPct.get('val', '') if buSzPct is not None else ''
            
            text = ''.join(t.text or '' for t in para.findall('.//a:t', ns))
            if text.strip() or True:
                print(f'  p[{i}]: attrs={attrs}')
                print(f'         lnSpc={lnSpc_val} spcBef={spcBef_val} spcAft={spcAft_val}')
                print(f'         buChar={repr(bu_char)} buFont={bu_font} buNone={bu_none} buSzPct={bu_sz}')
                
                # runs
                for rPr in para.findall('.//a:rPr', ns):
                    sz = rPr.get('sz', '')
                    b = rPr.get('b', '')
                    baseline = rPr.get('baseline', '')
                    print(f'         rPr: sz={sz} b={b} baseline={baseline}')
                    break
                
                print(f'         text: {repr(text[:50])}')
                print()
        break  # only one shape
