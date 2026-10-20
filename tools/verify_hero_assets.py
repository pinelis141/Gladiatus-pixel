"""Validate 128x144 paper-doll sprites and produce a visual QA image."""
from pathlib import Path
from PIL import Image, ImageDraw

DIR=Path('assets/sprites')
ART=['gladiator_base_hd','equip_boots_hd','equip_gloves_hd','equip_armor_hd',
     'equip_helmet_hd','equip_weapon_hd','equip_shield_hd',
     'gladiator_equipped_hd']
SIZE=(128,144)

def run():
    sprites={}
    for name in ART:
        file=DIR/f'{name}.png'
        if not file.is_file():
            raise RuntimeError(f'Missing visual asset: {file}')
        with Image.open(file) as im:
            im.load()
            if im.size!=SIZE:
                raise RuntimeError(f'{name} must be {SIZE}, got {im.size}')
            rgba=im.convert('RGBA')
            alpha=rgba.getchannel('A')
            if alpha.getbbox() is None:
                raise RuntimeError(f'{name} has empty alpha')
            if min(alpha.getextrema())!=0 or max(alpha.getextrema())<200:
                raise RuntimeError(f'{name} has defective alpha channel')
            sprites[name]=rgba.copy()

    # Regression: the gladius grip must actually overlap the left hand
    # on the base sprite. Earlier builds showed a floating sword.
    grip=(31,66,52,89)
    hero_alpha=sprites['gladiator_base_hd'].getchannel('A').crop(grip)
    blade_alpha=sprites['equip_weapon_hd'].getchannel('A').crop(grip)
    contact=sum(1 for a,b in zip(hero_alpha.get_flattened_data(),
                                  blade_alpha.get_flattened_data())
                if a>100 and b>100)
    if contact<45:
        raise RuntimeError(
            f'Weapon detached from hand: only {contact} overlapping pixels.'
        )

    mod=sprites['gladiator_base_hd'].copy()
    for name in ART[1:-1]:
        mod.alpha_composite(sprites[name])

    # Transparent PNG export retains exact pixel edges on enlargement.
    target=Path('assets/previews')
    target.mkdir(parents=True,exist_ok=True)
    sheet=Image.new('RGBA',(SIZE[0]*3,SIZE[1]),(0,0,0,0))
    for i,im in enumerate([sprites[ART[0]],mod,sprites[ART[-1]]]):
        sheet.alpha_composite(im,(SIZE[0]*i,0))
    sheet.save(target/'gladiator_comparison.png')
    print('Hero HD verified: 8 RGBA PNGs at 128x144, plus comparison sheet.')

if __name__=='__main__':
    run()
