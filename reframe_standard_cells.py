"""Uniform geometry adjustment of existing bitmap cells; never generates sprite art."""
from pathlib import Path
import argparse, json
from PIL import Image

p = argparse.ArgumentParser()
p.add_argument('--frames-root', required=True)
p.add_argument('--json-out', required=True)
a = p.parse_args()
root = Path(a.frames_root)
states = ['idle','running-right','running-left','waving','failed','waiting','running','review']
scale = 8 / 9
size = (round(192 * scale), round(208 * scale))
offset = ((192 - size[0]) // 2, 208 - size[1])
for state in states:
    for file in sorted((root / state).glob('*.png')):
        original = Image.open(file).convert('RGBA')
        resized = original.resize(size, Image.Resampling.LANCZOS)
        result = Image.new('RGBA', (192,208), (0,0,0,0))
        result.alpha_composite(resized, offset)
        result.save(file)
report = {
    'scope': states, 'uniform_scale': scale, 'resampled_cell': size,
    'offset': offset, 'jumping': 'unchanged; original stable-slot vertical arc preserved',
    'basis': 'Independent native-size review found jump head/body 10-15% smaller than standing states. Reframe the other eight states uniformly; do not enlarge/crop the jump apex.',
    'artwork_changes': 'None: only one shared cell resize/placement per affected state.'
}
Path(a.json_out).write_text(json.dumps(report,indent=2), encoding='utf-8')
print(json.dumps(report))
