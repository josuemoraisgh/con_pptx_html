import zipfile, xml.etree.ElementTree as ET

pptx = zipfile.ZipFile('assets/presentation.pptx')
data = pptx.read('ppt/slideLayouts/slideLayout6.xml')
root = ET.fromstring(data)

SLIDE_W_EMU = 9144000
CANVAS_W = 960.0
def emu_to_px(e): return int(e) * CANVAS_W / SLIDE_W_EMU

NS_PML = '{http://schemas.openxmlformats.org/presentationml/2006/main}'

for sp in root.findall('.//' + NS_PML + 'sp'):
    ph = next((c for c in sp if c.tag.endswith('}ph')), None)
    if ph is None:
        continue
    spPr = next((c for c in sp if c.tag.endswith('}spPr')), None)
    if spPr is None:
        continue
    xfrm = next((c for c in spPr if c.tag.endswith('}xfrm')), None)
    ph_type = ph.get('type', '')
    ph_idx = ph.get('idx', '')
    if xfrm is None:
        print(f'ph type={ph_type} idx={ph_idx} - NO xfrm (inherits from master)')
        continue
    off = next((c for c in xfrm if c.tag.endswith('}off')), None)
    ext = next((c for c in xfrm if c.tag.endswith('}ext')), None)
    if off is not None and ext is not None:
        x = int(off.get('x', 0))
        y = int(off.get('y', 0))
        cx = int(ext.get('cx', 0))
        cy = int(ext.get('cy', 0))
        print(f'ph type={ph_type} idx={ph_idx} - x={emu_to_px(x):.0f} y={emu_to_px(y):.0f} w={emu_to_px(cx):.0f} h={emu_to_px(cy):.0f}')
