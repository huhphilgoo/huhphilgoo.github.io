#!/usr/bin/env python3
"""Copy PaintBoardPro's real app renders into raw/ (for template.html) and the
gallery images into paintboardpro/assets/.

    python3 src/promo/paintboardpro/prep.py
    python3 src/promo/render.py paintboardpro
    python3 src/build.py

Sources (both produced in the paintboard app repo, see its WORKLOG):
  - integration_test/landing_art.dart → the macOS sandbox temp dir below
    (<scene>_ui.png with the toolbar, <scene>_art.png without; ko/en/ja)
  - the same tool with --dart-define=DUO=true --dart-define=ONLY=village
    (the foldable layout, written to <lang>/duo/)
Every picture was drawn by the app itself; nothing here is painted by hand.
"""
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
SITE = HERE.parents[2]
ART = Path.home() / 'Library/Containers/com.huhfeelgood.paintboard/Data/tmp/landing_art'
PAGE = (98, 98, 98 + 2556, 98 + 1868)   # the page inside a 2752×2064 render
SCENES = ['village', 'bouquet', 'city', 'fish', 'card']
LANGS = ['ko', 'en', 'ja']


def save(img: Image.Image, dest: Path, width: int, quality: int = 88) -> None:
    img = img.convert('RGB')
    img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest, 'JPEG', quality=quality, optimize=True, progressive=True)
    print(f'  {dest.relative_to(SITE)}  {img.size[0]}x{img.size[1]}')


def main() -> None:
    raw = HERE / 'raw'
    for lang in LANGS:
        for s in SCENES:
            ui = Image.open(ART / lang / f'{s}_ui.png')
            art = Image.open(ART / lang / f'{s}_art.png').crop(PAGE)
            save(ui, raw / f'{s}_ui_{lang}.jpg', 1600)
            save(art, raw / f'{s}_art_{lang}.jpg', 1600)
            # gallery on the landing page: the picture alone
            save(art, SITE / 'paintboardpro/assets' / f'art-{s}_{lang}.jpg', 1200, 84)
        # the village drawn again at iPhone Duo size, in the foldable layout
        # (landing_art.dart with --dart-define=DUO=true --dart-define=ONLY=village)
        save(Image.open(ART / lang / 'duo' / 'village_ui.png'), raw / f'duo_{lang}.jpg', 1600)
    for name in ('shapes_before', 'shapes_after'):
        save(Image.open(ART / 'ko' / f'{name}.png').crop(PAGE), raw / f'{name}.jpg', 1400)


if __name__ == '__main__':
    main()
