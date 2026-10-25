"""Positive right-facing reference board using only approved existing pixels."""
from pathlib import Path
from PIL import Image
import sys
run=Path(sys.argv[1])
right=Image.open(run/'decoded/look-anchors/090.png').convert('RGBA')
head=right.crop((0,0,192,130)).resize((768,520),Image.Resampling.NEAREST)
whole=right.resize((576,624),Image.Resampling.NEAREST)
strip=Image.open(run/'decoded/look-anchors-approved.png').convert('RGBA')
board=Image.new('RGB',(1536,1000),'#edf1f4')
board.paste(head,(16,10),head); board.paste(whole,(880,10),whole)
board.paste(strip,(384,760),strip)
board.save(run/'references/right-priority-cardinals.png')
print('Approved RIGHT head/body emphasized; exact four-cardinal strip retained below.')
