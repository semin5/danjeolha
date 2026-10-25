"""Restore approved v2 package, preserving the approved thinking-arm repair."""
from pathlib import Path
import hashlib,json
from PIL import Image
root=Path(__file__).parent
bpath=Path('C:/Users/semin5/IdeaProjects/danjeolha-pet/repair-a-arms-20261018/backup/spritesheet.webp')
apath=root/'backup-A/spritesheet.webp'
assert hashlib.sha256(bpath.read_bytes()).hexdigest()=='5b4f12c6a7946845b576df46740c128dab885ee3623f97b3af076ae1cca0d91d'
assert hashlib.sha256(apath.read_bytes()).hexdigest()=='fe87a44cb05e54839fbab8d33ec0fbfda1db4ed63dab985e3b7444f6b3191019'
with Image.open(bpath) as im:b=im.convert('RGBA')
with Image.open(apath) as im:a=im.convert('RGBA')
assert b.size==(1536,2288) and a.size==(1536,1872)
box=(0,1456,1536,1664)
result=b.copy();result.paste(a.crop(box),(0,1456))
out=root/'final/spritesheet.webp'
result.save(out,format='WEBP',lossless=True,quality=100,method=6,exact=True)
with Image.open(out) as im:encoded=im.convert('RGBA')
assert encoded.crop(box).tobytes()==a.crop(box).tobytes()
for row in range(11):
    if row==7:continue
    bounds=(0,row*208,1536,(row+1)*208)
    assert encoded.crop(bounds).tobytes()==b.crop(bounds).tobytes(),f'Changed restored row{row}'
assert encoded.crop((0,1872,1536,2288)).tobytes()==b.crop((0,1872,1536,2288)).tobytes()
report={'ok':True,'mode':'B','spriteVersionNumber':2,'dimensions':[1536,2288],
 'look_directions':16,'all16_look_cells_exact_RGBA_match_original_B':True,
 'all_other_B_rows_exact_RGBA_match':True,'thinking_row_exact_RGBA_match_repaired_A':True,
 'thinking_frames':6,'new_generation':False,'new_resampling':False,'new_chroma_cleanup':False,
 'source_B':str(bpath),'source_A':str(apath),'final_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),
 'prior_direction_QA':'C:/Users/semin5/IdeaProjects/danjeolha-pet/run-20261018/qa/direction-blind-validation.json',
 'prior_arm_QA':'C:/Users/semin5/IdeaProjects/danjeolha-pet/repair-a-arms-20261018/qa/final-visual-review.json'}
(root/'qa/restore-proof.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
