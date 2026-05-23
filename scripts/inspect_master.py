import zipfile, xml.etree.ElementTree as ET

ns = {
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'p': 'http://schemas.openxmlformats.org/presentationml/2006/main',
}

# Check slide master for lstStyle defaults
with zipfile.ZipFile('assets/presentation.pptx') as z:
    files = z.namelist()
    masters = [f for f in files if 'slideMasters/slideMaster' in f and f.endswith('.xml')]
    layouts = [f for f in files if 'slideLayouts/slideLayout' in f and f.endswith('.xml')]
    
    print('Masters:', masters)
    print('Layouts:', layouts[:5])
    
    # Parse slide master
    if masters:
        tree = ET.parse(z.open(masters[0]))
        root = tree.getroot()
        
        # Find txStyles
        txStyles = root.find('.//p:txStyles', ns)
        if txStyles:
            for style_el in txStyles:
                tag = style_el.tag.split('}')[1] if '}' in style_el.tag else style_el.tag
                print(f'\nStyle: {tag}')
                for lvl_el in style_el.findall('.//a:lvl1pPr', ns):
                    spcBef = lvl_el.find('a:spcBef', ns)
                    spcAft = lvl_el.find('a:spcAft', ns)
                    lnSpc = lvl_el.find('a:lnSpc', ns)
                    defRPr = lvl_el.find('a:defRPr', ns)
                    sz = defRPr.get('sz', '') if defRPr is not None else ''
                    
                    spcBef_val = ''
                    if spcBef is not None:
                        for child in spcBef:
                            tag2 = child.tag.split('}')[1]
                            spcBef_val = f'{tag2}={child.get("val","")}'
                    
                    spcAft_val = ''
                    if spcAft is not None:
                        for child in spcAft:
                            tag2 = child.tag.split('}')[1]
                            spcAft_val = f'{tag2}={child.get("val","")}'

                    lnSpc_val = ''
                    if lnSpc is not None:
                        for child in lnSpc:
                            tag2 = child.tag.split('}')[1]
                            lnSpc_val = f'{tag2}={child.get("val","")}'
                    
                    print(f'  lvl1: spcBef={spcBef_val} spcAft={spcAft_val} lnSpc={lnSpc_val} sz={sz}')
