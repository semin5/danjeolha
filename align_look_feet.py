"""Translate whole registered cells to the bare-foot anchor, without altering art."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

p = argparse.ArgumentParser()
p.add_argument('--atlas', required=True)
p.add_argument('--output', required=True)
p.add_argument('--webp-output', required=True)
p.add_argument('--row9-output', required=True)
p.add_argument('--report', required=True)
a = p.parse_args()
source = Path(a.atlas)
atlas = Image.open(source).convert('RGBA')
assert atlas.size == (1536, 2288)

def foot_anchor(cell):
    # Independent QA identified distinct foot and hair alpha components below
    # local y180. The contiguous leg/foot component is consistently larger.
    remaining = {(x,y) for y in range(180,208) for x in range(192)
                 if cell.getpixel((x,y))[3] > 128}
    components = []
    while remaining:
        seed = remaining.pop()
        stack, component = [seed], [seed]
        while stack:
            x,y = stack.pop()
            for neighbor in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    stack.append(neighbor)
                    component.append(neighbor)
        components.append(component)
    points = max(components, key=len)
    assert len(points) >= 700, f'Insufficient foot evidence: {len(points)}'
    xs, ys = zip(*points)
    return {'center_x': (min(xs)+max(xs))/2,
            'bottom': max(ys)+1,
            'bbox': [min(xs), min(ys), max(xs)+1, max(ys)+1],
            'component_pixel_count': len(points),
            'component_sizes': sorted(map(len,components),reverse=True)}

neutral = atlas.crop((1152, 0, 1344, 208))
target = foot_anchor(neutral)
records = []
for i in range(16):
    col, row = i % 8, 9 + i // 8
    box = (col*192, row*208, (col+1)*192, (row+1)*208)
    cell = atlas.crop(box)
    before = foot_anchor(cell)
    dx = round(target['center_x'] - before['center_x'])
    dy = target['bottom'] - before['bottom']
    bounds = cell.getbbox()
    assert bounds[0]+dx >= 2 and bounds[2]+dx <= 190
    assert bounds[1]+dy >= 2 and bounds[3]+dy <= 206
    shifted = Image.new('RGBA', (192, 208))
    shifted.alpha_composite(cell, (dx, dy))
    assert sum(shifted.getchannel('A').histogram()[1:]) == sum(cell.getchannel('A').histogram()[1:])
    atlas.paste(shifted, (col*192, row*208))
    records.append({'degrees': i*22.5, 'before': before, 'translation': [dx,dy],
                    'after': foot_anchor(shifted)})

atlas.save(a.output)
atlas.save(a.webp_output, format='WEBP', lossless=True, quality=100, method=6, exact=True)
atlas.crop((0, 1872, 1536, 2080)).save(a.row9_output)
report = {'ok': True, 'method': 'whole-cell integer translation from independently verified lower-leg alpha component bbox',
          'source': str(source), 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'shared_scale_unchanged': .5133531157270029, 'neutral_anchor': target,
          'art_pixels_painted_or_regenerated': False, 'cells': records}
Path(a.report).write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
