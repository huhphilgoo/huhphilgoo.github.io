#!/usr/bin/env python3
"""Render an app's promo images (landing-page screenshots) from its HTML template.

    python3 src/promo/render.py velozpad

Reads src/promo/<slug>/promo.json, prepares any derived crops the template needs,
renders every scene × language with headless Chrome at 2× and saves 1600×1000 JPGs
into <slug>/assets/<prefix><scene>_<lang>.jpg — the paths apps.json points at.
Change `prefix` in promo.json when the images change: a new file name is what makes
browsers drop the old picture (same name → a cached old image keeps showing).

Needs Google Chrome and Pillow (`pip3 install pillow`). See src/promo/README.md.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
W, H = 1600, 1000


def prepare(app_dir: Path, conf: dict) -> None:
    """Cut the regions the template shows on their own (e.g. a knob, a sheet)."""
    raw = app_dir / 'raw'
    for crop in conf.get('crops', []):
        for lang in conf['langs']:
            src = Image.open(raw / f"{crop['from']}_{lang}.png").convert('RGB')
            box = crop.get('box')
            if crop.get('trimTop'):
                # Drop the flat band above a bottom sheet: first row that differs
                # from the top-left pixel, scanning the middle column.
                top, y = src.getpixel((4, 4)), 0
                while y < src.height and src.getpixel((src.width // 2, y)) == top:
                    y += 1
                box = (0, y, src.width, src.height)
            src.crop(tuple(box)).save(raw / f"{crop['name']}_{lang}.png")


def render(app_dir: Path, conf: dict, out_dir: Path) -> None:
    template = app_dir / 'template.html'
    out_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for lang in conf['langs']:
            for scene in conf['scenes']:
                png = Path(tmp) / f'{scene}_{lang}.png'
                subprocess.run([
                    CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=2', f'--window-size={W},{H}',
                    '--allow-file-access-from-files', '--virtual-time-budget=2000',
                    f'--screenshot={png}', f'{template.as_uri()}#scene={scene}&lang={lang}',
                ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                img = Image.open(png).convert('RGB')
                if img.size != (W * 2, H * 2):
                    sys.exit(f'{scene}_{lang}: unexpected size {img.size}')
                dest = out_dir / f"{conf.get('prefix', '')}{scene}_{lang}.jpg"
                img.resize((W, H), Image.LANCZOS).save(dest, quality=86, optimize=True)
                print(f'  {dest.relative_to(ROOT)}')


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    slug = sys.argv[1]
    app_dir = ROOT / 'src' / 'promo' / slug
    conf = json.loads((app_dir / 'promo.json').read_text(encoding='utf-8'))
    prepare(app_dir, conf)
    render(app_dir, conf, ROOT / slug / 'assets')


if __name__ == '__main__':
    main()
