"""Use the bundled deterministic chroma/cell fitter for one reference anchor."""
from pathlib import Path
import argparse, json, sys
from PIL import Image
p = argparse.ArgumentParser()
for key in ['skill','source','output','json-out','direction','chroma-key']:
    p.add_argument('--' + key, required=True)
a = p.parse_args()
sys.path.insert(0, str(Path(a.skill) / 'scripts'))
import extract_cardinal_anchors as bundled
im = bundled.remove_chroma_background(Image.open(a.source), bundled.parse_hex_color(a.chroma_key), 96)
used = bundled.alpha_count(im)
edge = bundled.edge_alpha_count(im, 2)
if used < 400 or edge > 24:
    raise SystemExit(f'Anchor source fails: used={used}, edge={edge}')
bundled.fit_to_cell(im).save(a.output)
report = {'ok':True, 'direction':a.direction, 'source':a.source, 'output':a.output, 'used_pixels':used, 'edge_pixels':edge}
Path(a.json_out).write_text(json.dumps(report,indent=2), encoding='utf-8')
print(json.dumps(report))
