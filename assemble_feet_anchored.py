"""Run preliminary bundled atlas registration with a narrow lower-body band.

Only existing pixels are cropped/resized/placed by the bundled assembler.
The original lower 28% centroid includes this avatar's moving long ponytail.
The lowest 4.5% reduces that contamination but does not fully exclude the tail.
For this run, align_look_feet.py performs the required final whole-cell
registration using independently verified lower-leg connected components.
"""
from pathlib import Path
import argparse, sys
p=argparse.ArgumentParser(add_help=False)
p.add_argument('--skill-dir', required=True)
a, remaining=p.parse_known_args()
sys.path.insert(0,str(Path(a.skill_dir)/'scripts'))
import assemble_extended_atlas as bundled
def foot_band(points, top, bottom):
    threshold=bottom-max(3,(bottom-top)*0.045)
    return [(x,y) for x,y in points if y>=threshold] or points
bundled.lower_band_points=foot_band
sys.argv=[sys.argv[0],*remaining]
bundled.main()
