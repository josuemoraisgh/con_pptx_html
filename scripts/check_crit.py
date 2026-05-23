import zipfile, xml.etree.ElementTree as ET, sys
import warnings
warnings.filterwarnings('ignore')

pptx = zipfile.ZipFile('assets/presentation.pptx')
data = pptx.read('ppt/slides/slide13.xml')
root = ET.fromstring(data)

NS_PML = '{http://schemas.openxmlformats.org/presentationml/2006/main}'
SLIDE_W_EMU = 12192000
CANVAS_W = 960.0
def px(e): return int(e) * CANVAS_W / SLIDE_W_EMU

# Find ALL sp elements with CRIT text
for sp in root.findall('.//' + NS_PML + 'sp'):
    texts = [el.text or '' for el in sp.iter() if el.tag.endswith('}t')]
    alltext = ' '.join(texts)
    if 'CRIT' not in alltext:
        continue
    spPr = next((c for c in sp if c.tag.endswith('}spPr')), None)
    if spPr is None:
        print('No spPr for CRIT')
        continue
    xfrm = next((c for c in spPr if c.tag.endswith('}xfrm')), None)
    if xfrm is not None:
        off = next((c for c in xfrm if c.tag.endswith('}off')), None)
        ext = next((c for c in xfrm if c.tag.endswith('}ext')), None)
        if off is not None and ext is not None:
            x = int(off.get('x', 0))
            cx = int(ext.get('cx', 0))
            print('CRIT box: x=' + str(round(px(x))) + ' w=' + str(round(px(cx))) + ' availW=' + str(round(px(cx) - 2 * px(228600))))
    else:
        print('CRIT sp has NO xfrm. Text: ' + alltext[:40])
