"""Deterministic crop/registration/QA of existing bitmap art; no generated drawing."""
from pathlib import Path
import argparse, hashlib, json, sys
from PIL import Image, ImageDraw

p=argparse.ArgumentParser()
p.add_argument('--run',required=True)
p.add_argument('--skill',required=True)
p.add_argument('--stage',choices=['base','normalize','decode-clean','proof'],required=True)
a=p.parse_args()
root=Path(a.run)
sys.path.insert(0,str(Path(a.skill)/'scripts'))
from extract_strip_frames import remove_chroma_background, component_frame_groups, component_group_image, component_bounds
from compose_atlas import clear_transparent_rgb
SPECS=[('idle',6),('running-right',8),('running-left',8),('waving',4),('jumping',5),('failed',8),('waiting',6),('running',6),('review',6)]

def opened(path):
    with Image.open(path) as im:
        return im.convert('RGBA')

def write_json(path,data):
    path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')

def crop_cell(atlas,row,col):
    return atlas.crop((192*col,208*row,192*(col+1),208*(row+1)))

def foot_anchor(cell):
    pending={(x,y) for y in range(180,208) for x in range(192) if cell.getpixel((x,y))[3]>128}
    components=[]
    while pending:
        seed=pending.pop()
        stack,part=[seed],[seed]
        while stack:
            x,y=stack.pop()
            for q in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                if q in pending:
                    pending.remove(q);stack.append(q);part.append(q)
        components.append(part)
    part=max(components,key=len)
    assert len(part)>200,'No usable planted foot component'
    xs,ys=zip(*part)
    return {'center_x':(min(xs)+max(xs))/2,'bottom':max(ys)+1,'bbox':[min(xs),min(ys),max(xs)+1,max(ys)+1],'area':len(part)}

if a.stage=='base':
    old=opened(root/'backup/spritesheet.webp')
    assert old.size==(1536,2288)
    for row,(state,count) in enumerate(SPECS):
        folder=root/'frames'/state
        folder.mkdir(parents=True,exist_ok=True)
        for col in range(count):
            crop_cell(old,row,col).save(folder/f'{col:02d}.png')
    base=old.crop((0,0,1536,1872))
    base.paste((0,0,0,0),(1152,0,1536,208))
    base.save(root/'final/base-A.png')
    print('Copied57 used standard cells; removed v2 neutral/look-only slots for explicit A format.')

elif a.stage=='normalize':
    strip=remove_chroma_background(opened(root/'decoded/running.png'),(0,255,0),96)
    groups=component_frame_groups(strip,6)
    assert groups is not None and len(groups)==6
    boxes=[component_bounds(g) for g in groups]
    assert all(boxes[i][2]<boxes[i+1][0] for i in range(5)),'Overlapping source poses'
    assert min(b[0] for b in boxes)>1 and max(b[2] for b in boxes)<strip.width-1,'Source outer clipping'
    crops=[component_group_image(strip,g).crop(component_group_image(strip,g).getbbox()) for g in groups]
    neutral=opened(root/'frames/idle/00.png')
    target=foot_anchor(neutral)
    nb=neutral.getbbox()
    height=nb[3]-nb[1]
    scale=min(height/max(c.height for c in crops),180/max(c.width for c in crops),1)
    row_image=Image.new('RGBA',(1536,208))
    records=[]
    for i,crop in enumerate(crops):
        sprite=crop.resize((round(crop.width*scale),round(crop.height*scale)),Image.Resampling.LANCZOS)
        cell=Image.new('RGBA',(192,208))
        cell.alpha_composite(sprite,((192-sprite.width)//2,205-sprite.height))
        before=foot_anchor(cell)
        dx=round(target['center_x']-before['center_x'])
        dy=target['bottom']-before['bottom']
        b=cell.getbbox()
        assert b[0]+dx>=2 and b[2]+dx<=190 and b[1]+dy>=2 and b[3]+dy<=206,'Final registration clips'
        output=Image.new('RGBA',(192,208))
        output.alpha_composite(cell,(dx,dy))
        output=clear_transparent_rgb(output)
        assert output.getchannel('A').histogram()==cell.getchannel('A').histogram(),'Pixel loss'
        output.save(root/'frames/running'/f'{i:02d}.png')
        row_image.paste(output,(i*192,0))
        records.append({'index':i,'source_bbox':boxes[i],'bbox':output.getbbox(),'translation':[dx,dy],'foot':foot_anchor(output)})
    row_image.save(root/'qa/running-registered-preclean.png')
    write_json(root/'qa/running-normalization.json',{'ok':True,'method':'ordered component groups, one shared scale, whole-cell planted-foot registration','shared_scale':scale,'neutral_anchor':target,'frame_count':6,'frames':records})
    print('Registered six coherent source poses with shared scale and planted-foot anchors.')

elif a.stage=='decode-clean':
    row_image=opened(root/'qa/running-cleaned.png')
    assert row_image.size==(1536,208)
    for i in range(6):
        crop_cell(row_image,0,i).save(root/'frames/running'/f'{i:02d}.png')
    manifest={'ok':True,'chroma_key':{'hex':'#00FF00','rgb':[0,255,0],'threshold':96},'rows':[]}
    for state,count in SPECS:
        manifest['rows'].append({'state':state,'frames':[str(root/'frames'/state/f'{i:02d}.png') for i in range(count)],'method':'components' if state=='running' else 'existing-approved-atlas'})
    write_json(root/'frames/frames-manifest.json',manifest)
    print('Decoded the single-cleaned new thinking row; other eight state pixels unchanged.')

elif a.stage=='proof':
    atlas=opened(root/'final/spritesheet.webp')
    old=opened(root/'backup/spritesheet.webp')
    assert atlas.size==(1536,1872)
    preserved=[]
    for row,(state,count) in enumerate(SPECS):
        if state=='running':continue
        for col in range(count):
            assert crop_cell(atlas,row,col).tobytes()==crop_cell(old,row,col).tobytes(),f'Changed approved {state}/{col}'
        preserved.append(state)
    write_json(root/'qa/preserved-state-pixels.json',{'ok':True,'states':preserved,'preserved_frames':51,'exact_RGBA_match':True,'look_direction_count':0,'A_dimensions':[1536,1872]})
    sheet=Image.new('RGB',(192*7,240),'#f4f6f8')
    for col,cell in enumerate([crop_cell(atlas,0,0)]+[crop_cell(atlas,7,i) for i in range(6)]):
        sheet.paste(cell,(col*192,22),cell)
        ImageDraw.Draw(sheet).text((col*192+6,5),'neutral' if col==0 else f'thinking {col-1}',fill='black')
    sheet.save(root/'qa/thinking-native.png')
    for band in range(3):
        board=Image.new('RGB',(192*8,238*3),'#f4f6f8')
        for j in range(3):
            ri=band*3+j
            state,count=SPECS[ri]
            for col in range(count):
                cell=crop_cell(atlas,ri,col)
                board.paste(cell,(192*col,238*j+25),cell)
                ImageDraw.Draw(board).text((192*col+4,238*j+6),f'{state} {col}',fill='black')
        board.save(root/'qa'/f'states-native-{band+1}.png')
    print('All51 unchanged state frames are bit-for-bit preserved. Native QA proofs ready.')
