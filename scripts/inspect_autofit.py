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

        bodyPr = txBody.find('a:bodyPr', ns)
        
        # Check normAutofit
        normAutofit = txBody.find('.//a:bodyPr/a:normAutofit', ns)
        noAutofit = txBody.find('.//a:bodyPr/a:noAutofit', ns)
        spAutoFit = txBody.find('.//a:bodyPr/a:spAutoFit', ns)
        
        fs = normAutofit.get('fontScale', '') if normAutofit is not None else ''
        lsr = normAutofit.get('lnSpcReduction', '') if normAutofit is not None else ''
        
        # bodyPr attributes
        bPr_attrs = dict(bodyPr.attrib) if bodyPr is not None else {}
        
        print(f'Shape {sp_idx}: {sp_name}')
        print(f'  normAutofit: {normAutofit is not None} fs={fs} lsr={lsr}')
        print(f'  noAutofit: {noAutofit is not None}')
        print(f'  spAutoFit: {spAutoFit is not None}')
        print(f'  bodyPr: {bPr_attrs}')
        print()
