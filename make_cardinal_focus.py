"""Reference-only pixel crops/enlargements and an unlabeled diagnostic pair sheet."""
from pathlib import Path
from PIL import Image, ImageDraw
import sys
run=Path(sys.argv[1]); root=run/'decoded/look-anchors'
cells=[Image.open(root/f'{d}.png').convert('RGBA') for d in ['000','090','180','270']]
board=Image.new('RGB',(1536,840),'#edf1f4')
for i,c in enumerate(cells):
    head=c.crop((0,0,192,130)).resize((384,260),Image.Resampling.NEAREST)
    board.paste(head,(i*384,0),head)
    whole=c.resize((384,416),Image.Resampling.NEAREST)
    board.paste(whole,(i*384,340),whole)
board.save(run/'references/cardinal-focus.png')
probe=Image.new('RGB',(384,472),'#edf1f4'); draw=ImageDraw.Draw(probe)
for row,(axis,a,b) in enumerate([('horizontal',cells[3],cells[1]),('vertical',cells[2],cells[0])]):
    y=row*236
    draw.text((6,y+2),axis,fill='#111111')
    for col,c in enumerate([a,b]):
        draw.text((col*192+88,y+15),'AB'[col],fill='#111111')
        probe.paste(c,(col*192,y+28),c)
probe.save(run/'qa/cardinal-probe.png')
print('Cardinal focus and unlabeled diagnostic probe ready.')
