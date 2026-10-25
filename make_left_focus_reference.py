"""Compose approved existing left anchor and standard QA as one grounding input."""
from pathlib import Path
from PIL import Image
import sys
run=Path(sys.argv[1])
c=Image.open(run/'decoded/look-anchors/270.png').convert('RGBA')
head=c.crop((0,0,192,130)).resize((576,390),Image.Resampling.NEAREST)
whole=c.resize((576,624),Image.Resampling.NEAREST)
standard=Image.open(run/'qa/contact-sheet.png').convert('RGB')
standard.thumbnail((1000,1200),Image.Resampling.LANCZOS)
board=Image.new('RGB',(1640,1240),'#edf1f4')
board.paste(head,(22,10),head)
board.paste(whole,(22,440),whole)
board.paste(standard,(630+(1000-standard.width)//2,(1240-standard.height)//2))
board.save(run/'references/left-priority-standard.png')
print('Approved LEFT anchor + standard reference bundled.')
