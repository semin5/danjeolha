"""Render and decode motion previews from the exact user-selected v1 atlas."""
from pathlib import Path
import argparse,json
from PIL import Image,ImageDraw,ImageSequence
p=argparse.ArgumentParser();p.add_argument('--run',required=True);a=p.parse_args();root=Path(a.run)
with Image.open(root/'final/spritesheet.webp') as im:atlas=im.convert('RGBA')
assert atlas.size==(1536,1872)
specs=[('idle',[280,110,110,140,140,320]),('running-right',[120]*7+[220]),('running-left',[120]*7+[220]),('waving',[140]*3+[280]),('jumping',[140]*4+[280]),('failed',[140]*7+[240]),('waiting',[150]*5+[260]),('running',[120]*5+[220]),('review',[150]*5+[280])]
out=root/'qa/previews';out.mkdir(exist_ok=True)
combined,timing,metadata=[],[],[]
def preview(cell,label):
    frame=Image.new('RGB',(240,248),'#f4f6f8');frame.paste(cell,(24,8),cell)
    ImageDraw.Draw(frame).text((12,225),label,fill='#29333c');return frame
def save(frames,durations,path):
    frames[0].save(path,save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=2,optimize=False)
for row,(state,durations) in enumerate(specs):
    frames=[preview(atlas.crop((i*192,row*208,(i+1)*192,(row+1)*208)),state) for i in range(len(durations))]
    path=out/f'{state}.gif';save(frames,durations,path)
    combined.extend(frames);timing.extend(durations)
    with Image.open(path) as gif:
        decoded=[f.convert('RGB') for f in ImageSequence.Iterator(gif)]
    with Image.open(path) as gif:
        actual_times=[f.info.get('duration') for f in ImageSequence.Iterator(gif)]
        loop=gif.info.get('loop')
    assert len(decoded)==len(durations) and actual_times==durations and loop==0
    metadata.append({'state':state,'frames':len(decoded),'durations_ms':actual_times,'loop':loop})
    if state=='running':
        sheet=Image.new('RGB',(240*6,248),'#f4f6f8')
        for i,frame in enumerate(decoded):sheet.paste(frame,(240*i,0))
        sheet.save(root/'qa/thinking-gif-frames.png')
save(combined,timing,out/'all-states.gif')
(root/'qa/gif-metadata.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
print('Exact final atlas previews rendered; all9 GIF counts, durations and loop metadata match contract.')
