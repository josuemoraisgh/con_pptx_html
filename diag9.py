import zipfile, re
z = zipfile.ZipFile('assets/presentation.pptx')
c = z.read('ppt/slides/slide9.xml').decode()
prsts = list(set(re.findall(r'prst="([^"]+)"', c)))
print('presets:', prsts)
print('cxnSp count:', c.count('cxnSp'))
print('leftRight:', c.count('leftRight'))
# Show cxnSp blocks
parts = c.split('<p:cxnSp')
print('cxnSp blocks:', len(parts)-1)
for p in parts[1:3]:
    end = p.find('</p:cxnSp>')
    print(p[:end+11])
    print('---')
