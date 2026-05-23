import zipfile, xml.etree.ElementTree as ET

pptx = zipfile.ZipFile('assets/presentation.pptx')
data = pptx.read('ppt/slideMasters/slideMaster1.xml')
root = ET.fromstring(data)

NS_PML = '{http://schemas.openxmlformats.org/presentationml/2006/main}'
SLIDE_W_EMU = 9144000
CANVAS_W = 960.0
SLIDE_H_EMU = 5143500
CANVAS_H = 540.0

def px_w(e): return int(e) * CANVAS_W / SLIDE_W_EMU
def px_h(e): return int(e) * CANVAS_H / SLIDE_H_EMU

for sp in root.findall('.//' + NS_PML + 'sp'):
    nvSpPr = next((c for c in sp if c.tag.endswith('}nvSpPr')), None)
    if nvSpPr is None: continue
    nvPr = next((c for c in nvSpPr if c.tag.endswith('}nvPr')), None)
    if nvPr is None: continue
    ph = next((c for c in nvPr if c.tag.endswith('}ph')), None)
    if ph is None: continue

    spPr = next((c for c in sp if c.tag.endswith('}spPr')), None)
    if spPr is None: continue
    xfrm = next((c for c in spPr if c.tag.endswith('}xfrm')), None)
    if xfrm is None: continue
    off = next((c for c in xfrm if c.tag.endswith('}off')), None)
    ext = next((c for c in xfrm if c.tag.endswith('}ext')), None)
    if off is None or ext is None: continue

    x = int(off.get('x', 0))
    y = int(off.get('y', 0))
    cx = int(ext.get('cx', 0))
    cy = int(ext.get('cy', 0))
    pt = ph.get('type', '')
    pi = ph.get('idx', '')
    print('ph type=' + pt + ' idx=' + pi + ' - x=' + str(round(px_w(x))) + ' y=' + str(round(px_h(y))) + ' w=' + str(round(px_w(cx))) + ' h=' + str(round(px_h(cy))))
