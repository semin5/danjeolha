"""Compose existing reference pixels only, to fit the five-image attachment limit."""
from PIL import Image
from pathlib import Path
import sys
run=Path(sys.argv[1])
canonical=Image.open(run/'references/canonical-base.png').convert('RGB')
canonical.thumbnail((640,680),Image.Resampling.LANCZOS)
original=Image.open(run/'references/reference-01.png').convert('RGB')
original=original.resize((original.width*4,original.height*4),Image.Resampling.NEAREST)
board=Image.new('RGB',(1360,720),'#f4f4f4')
board.paste(canonical,((680-canonical.width)//2,(720-canonical.height)//2))
board.paste(original,(710,(720-original.height)//2))
target=run/'references/look-identity-bundle.png'
board.save(target)
print(target)
