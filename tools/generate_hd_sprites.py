"""Original layered high-resolution pixel art assets. Pillow only; all art CC0-style original."""
from pathlib import Path
from random import Random
from PIL import Image, ImageDraw

OUT=Path('assets/sprites')
OUT.mkdir(parents=True,exist_ok=True)
S=2
INK=(22,15,21,255); SKIN=(204,149,101,255); SKIN_H=(242,192,135,255)
SHADE=(132,84,70,255); BRONZE=(161,107,52,255); GOLD=(225,181,83,255)
SHINE=(255,231,155,255); STEEL=(142,167,178,255)
STEEL_H=(219,231,230,255); STEEL_D=(66,88,110,255)
RED=(177,48,54,255); RED_D=(98,29,49,255)
LEATHER=(96,57,43,255); DARK=(42,27,39,255)

def sprite():
    return Image.new('RGBA',(64,72),(0,0,0,0))

def box(d,xy,c):
    d.rectangle(xy,fill=c)

def outline(im):
    old=im.copy()
    p=old.load();t=im.load()
    for y in range(im.height):
        for x in range(im.width):
            if p[x,y][3]:continue
            if any(0<=xx<im.width and 0<=yy<im.height and p[xx,yy][3]>0
                   for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1))):
                t[x,y]=INK
    return im

def save(name,im):
    outline(im).resize((128,144),Image.Resampling.NEAREST).save(OUT/(name+'.png'))

def gladiator():
    im=sprite();d=ImageDraw.Draw(im)
    # Silhouette and controlled shading layers
    d.ellipse((20,65,49,70),fill=(17,17,24,95))
    for x in (23,35):
        box(d,(x,43,x+8,63),SHADE)
        box(d,(x+1,45,x+5,60),SKIN)
        d.polygon([(x+5,47),(x+8,48),(x+7,58),(x+5,60)],fill=BRONZE)
        box(d,(x-1,60,x+9,66),LEATHER)
        box(d,(x,62,x+9,63),GOLD)
        box(d,(x-2,66,x+10,68),INK)
    # subligaculum
    d.polygon([(21,40),(43,40),(41,51),(36,48),(32,53),(27,48),(23,51)],fill=LEATHER)
    box(d,(23,41,41,44),GOLD)
    box(d,(28,42,34,44),SHINE)
    for x in (27,31,35,39):
        box(d,(x,45,x+1,49),BRONZE)
    # chest anatomy
    d.polygon([(24,18),(40,18),(45,27),(43,42),(22,42),(20,27)],fill=SHADE)
    d.polygon([(24,19),(39,19),(43,27),(40,39),(24,39),(22,29)],fill=SKIN)
    d.polygon([(24,22),(32,23),(30,29),(24,28)],fill=SKIN_H)
    d.polygon([(33,23),(40,22),(40,27),(34,29)],fill=SKIN_H)
    for y in (30,34,38):
        box(d,(26,y,29,y+2),SKIN_H)
        box(d,(34,y,38,y+2),BRONZE)
    box(d,(31,30,32,40),SHADE)
    # arms with leather bracers
    for x in (15,44):
        box(d,(x,20,x+5,39),SHADE)
        box(d,(x+1,22,x+3,34),SKIN)
        box(d,(x,32,x+6,38),LEATHER)
        for y in (33,36):
            box(d,(x+1,y,x+5,y),BRONZE)
        box(d,(x+1,39,x+5,42),SKIN)
    # face, hair, eye and jaw
    box(d,(28,14,36,19),SKIN)
    d.polygon([(25,5),(39,5),(41,15),(38,19),(26,19),(23,15)],fill=SHADE)
    d.polygon([(26,6),(38,6),(39,15),(36,18),(27,18),(25,14)],fill=SKIN)
    d.polygon([(26,6),(37,6),(33,12),(27,14)],fill=SKIN_H)
    box(d,(26,3,38,7),LEATHER)
    box(d,(24,7,27,9),LEATHER)
    box(d,(35,7,40,9),LEATHER)
    box(d,(27,12,29,13),INK);box(d,(34,12,36,13),INK)
    box(d,(30,16,34,17),SHADE)
    d.line((25,18,32,21,39,18),fill=LEATHER,width=1)
    save('gladiator_base_hd',im)

def armory():
    # armor overlapping exact base geometry
    im=sprite();d=ImageDraw.Draw(im)
    d.polygon([(23,17),(41,17),(46,25),(43,43),(21,43),(18,24)],fill=STEEL_D)
    for y in (21,26,31,36):
        box(d,(22,y,42,y+4),STEEL)
        box(d,(24,y,36,y),STEEL_H)
        box(d,(40,y,42,y+3),STEEL_D)
        for x in (24,39):
            box(d,(x,y+2,x+1,y+3),GOLD)
    box(d,(30,22,34,24),GOLD)
    d.polygon([(18,18),(26,18),(28,23),(22,29),(17,26)],fill=STEEL)
    d.polygon([(39,18),(46,18),(48,26),(43,29),(37,23)],fill=STEEL_D)
    box(d,(19,19,25,20),STEEL_H);box(d,(41,19,45,20),GOLD)
    box(d,(22,41,42,43),GOLD)
    save('equip_armor_hd',im)

    im=sprite();d=ImageDraw.Draw(im)
    # crested helmet leaves eyes visible through a face guard
    d.polygon([(26,5),(28,0),(36,0),(41,5),(40,8),(25,8)],fill=RED_D)
    for x,y in [(27,4),(29,2),(31,1),(34,1),(37,2),(39,4)]:
        box(d,(x,y,x+2,y+2),RED)
    d.polygon([(23,8),(26,4),(38,4),(41,8),(42,18),(37,21),(27,21),(22,18)],fill=BRONZE)
    d.polygon([(25,7),(30,5),(38,6),(39,10),(25,11)],fill=GOLD)
    box(d,(26,8,31,9),SHINE)
    box(d,(27,12,37,16),INK)
    box(d,(27,13,29,14),STEEL_H);box(d,(35,13,37,14),STEEL_H)
    box(d,(22,13,25,21),BRONZE)
    box(d,(39,13,42,21),BRONZE)
    box(d,(31,12,33,20),GOLD)
    for x in (23,40):
        box(d,(x,18,x+2,22),GOLD)
    save('equip_helmet_hd',im)

    im=sprite();d=ImageDraw.Draw(im)
    # steel gladius crossing the left fist
    d.polygon([(11,2),(14,5),(15,31),(11,33),(9,30)],fill=STEEL_D)
    d.polygon([(11,4),(13,6),(13,30),(11,31)],fill=STEEL_H)
    d.line((12,7,12,28),fill=(255,255,255,255),width=1)
    box(d,(7,32,18,34),GOLD);box(d,(9,33,15,33),SHINE)
    box(d,(11,35,14,44),LEATHER)
    for y in (36,39,42):
        box(d,(11,y,14,y),GOLD)
    box(d,(10,44,15,46),GOLD)
    save('equip_weapon_hd',im)

    im=sprite();d=ImageDraw.Draw(im)
    d.polygon([(47,18),(57,20),(62,25),(60,49),(54,54),(44,48),(43,25)],fill=GOLD)
    d.polygon([(47,20),(56,22),(60,26),(58,47),(54,51),(46,46),(45,25)],fill=RED_D)
    d.polygon([(47,22),(54,22),(52,49),(46,45)],fill=RED)
    d.polygon([(51,26),(56,27),(59,31),(55,33),(55,42),(51,42),(51,33),(46,30)],fill=GOLD)
    d.ellipse((48,32,56,40),fill=STEEL_D,outline=SHINE,width=1)
    for y in (23,46):
        d.line((46,y,58,y+3),fill=GOLD,width=1)
    save('equip_shield_hd',im)

    im=sprite();d=ImageDraw.Draw(im)
    for x in (15,44):
        d.polygon([(x,31),(x+6,31),(x+7,41),(x+1,43),(x-1,39)],fill=STEEL_D)
        box(d,(x,33,x+4,34),STEEL_H)
        box(d,(x+1,39,x+5,40),GOLD)
    save('equip_gloves_hd',im)

    im=sprite();d=ImageDraw.Draw(im)
    for x in (22,34):
        box(d,(x,51,x+10,65),BRONZE)
        box(d,(x+1,52,x+6,55),GOLD)
        for y in (57,60,63):
            box(d,(x,y,x+9,y),LEATHER)
        box(d,(x-1,65,x+10,68),STEEL_D)
        box(d,(x,65,x+5,66),STEEL_H)
    save('equip_boots_hd',im)

def opponent(name):
    im=Image.new('RGBA',(64,64),(0,0,0,0));d=ImageDraw.Draw(im)
    d.ellipse((7,55,55,59),fill=(10,10,15,90))
    if name=='wolf':
        d.polygon([(8,43),(11,28),(23,24),(39,28),(45,35),(54,32),(58,39),
                   (49,48),(24,49)],fill=(71,84,103,255))
        d.polygon([(14,27),(18,15),(24,24),(30,16),(36,31),(27,41),(10,36)],
                  fill=(127,144,158,255))
        d.polygon([(12,20),(16,10),(19,23)],fill=(68,72,83,255))
        d.polygon([(25,23),(29,12),(32,27)],fill=(68,72,83,255))
        d.polygon([(26,30),(40,32),(35,39),(27,38)],fill=(192,184,156,255))
        for x in (18,26,43,51):
            box(d,(x,43,x+4,56),(58,65,81,255))
            box(d,(x,54,x+4,57),INK)
        box(d,(19,28,21,29),RED)
        for x in (30,33):box(d,(x,39,x+1,42),STEEL_H)
    else:
        color = (117,63,51,255) if name=='minotaur' else                 (173,86,66,255) if name=='pirate' else                 (183,153,89,255)
        d.polygon([(17,21),(45,21),(51,37),(45,47),(17,47),(11,35)],fill=DARK)
        d.polygon([(20,21),(42,21),(45,39),(39,47),(20,47),(16,35)],fill=color)
        for x in (20,35):
            box(d,(x,44,x+8,55),SHADE)
            box(d,(x,51,x+9,58),LEATHER)
        for x in (10,46):
            box(d,(x,23,x+6,42),color)
            box(d,(x,34,x+7,42),LEATHER)
        if name=='minotaur':
            d.polygon([(21,14),(23,3),(17,1),(12,10),(18,17)],fill=SHINE)
            d.polygon([(39,14),(42,3),(47,1),(52,10),(45,17)],fill=SHINE)
            d.ellipse((20,7,44,26),fill=(103,55,42,255))
            box(d,(24,15,40,25),BRONZE)
            box(d,(26,18,29,20),RED)
            box(d,(35,18,38,20),RED)
            d.ellipse((28,23,36,28),fill=INK)
            box(d,(23,28,41,33),BRONZE)
            box(d,(23,30,41,31),SHINE)
        elif name=='pirate':
            box(d,(23,6,40,22),SKIN)
            box(d,(20,4,44,9),RED_D)
            box(d,(23,5,42,6),RED)
            box(d,(39,7,48,10),RED)
            box(d,(25,13,28,15),INK)
            box(d,(34,13,38,15),INK)
            box(d,(27,19,38,21),LEATHER)
            box(d,(8,12,11,43),STEEL_H)
            box(d,(7,42,14,44),GOLD)
        else:
            box(d,(22,9,41,23),BRONZE)
            d.polygon([(23,10),(26,5),(38,5),(43,11),(42,17),(22,17)],
                fill=STEEL)
            box(d,(26,11,38,13),STEEL_H)
            box(d,(27,17,38,19),INK)
            box(d,(32,16,34,24),GOLD)
            for y in (27,33,39):
                box(d,(20,y,43,y+2),STEEL)
                box(d,(22,y,35,y),STEEL_H)
            box(d,(4,21,8,50),STEEL_H)
            box(d,(3,45,10,47),GOLD)
    outline(im).resize((128,128),Image.Resampling.NEAREST).save(
        OUT/('enemy_'+name+'_hd.png'))

def scene(which):
    im=Image.new('RGB',(160,120));d=ImageDraw.Draw(im)
    colors={
      'colosseum':((28,19,37),(98,57,62),(108,76,60)),
      'forest':((18,26,41),(43,69,54),(65,76,48)),
      'port':((22,40,60),(81,98,102),(104,83,62)),
      'ruins':((43,22,42),(91,51,49),(79,62,51))}
    top,middle,bottom=colors[which]
    def blend(a,b,t):return tuple(round(v+(w-v)*t) for v,w in zip(a,b))
    for y in range(120):
        t=y/120
        d.line((0,y,160,y),fill=blend(top,middle,min(1,t*1.5)) if t<.7
               else blend(middle,bottom,(t-.7)/.3))
    rng=Random(80+len(which))
    if which=='forest':
        for x in (6,24,53,96,131,153):
            box(d,(x,24,x+5,96),(49,44,38))
            for yy in (10,25,39):
                d.ellipse((x-15,yy,x+17,yy+29),
                          fill=(26+rng.randrange(18),53+rng.randrange(25),43))
        for x in range(0,160,8):
            d.polygon([(x,100),(x+4,91),(x+11,101)],fill=(45,58,42))
    else:
        for x in (7,32,112,137):
            d.rectangle((x,16,x+12,98),fill=(95,77,68))
            d.rectangle((x+2,17,x+5,96),fill=(137,110,85))
            d.rectangle((x-2,15,x+14,19),fill=(165,131,95))
            d.rectangle((x-3,94,x+15,99),fill=(76,51,54))
        if which=='colosseum':
            for x in (40,66,92):
                d.ellipse((x-6,24,x+13,60),fill=(33,25,36))
                d.rectangle((x-6,43,x+13,62),fill=(33,25,36))
                for xx in range(x-5,x+14,3):
                    d.point((xx,63),fill=(190,114,76))
            d.polygon([(0,82),(80,65),(160,82),(160,94),(0,94)],fill=(110,78,59))
        elif which=='port':
            d.rectangle((0,73,160,90),fill=(39,77,103))
            for x in range(0,160,12):
                d.line((x,76,x+8,76),fill=(86,123,134))
            d.polygon([(58,18),(58,70),(104,68)],fill=(213,187,140))
            d.line((58,17,58,84),fill=(63,45,48),width=3)
            d.line((0,89,160,89),fill=(163,117,79),width=5)
        else:
            for x,y in ((50,40),(82,23),(99,49)):
                d.polygon([(x,y+31),(x+8,y-8),(x+14,y+31)],
                          fill=(156,47,39))
                d.polygon([(x+4,y+24),(x+8,y-3),(x+11,y+23)],
                          fill=(241,147,46))
                d.polygon([(x+6,y+20),(x+8,y+5),(x+10,y+20)],
                          fill=(247,209,98))
    for y in range(94,120,8):
        d.line((0,y,160,y),fill=(52,39,39),width=1)
    for x in range(0,160,18):
        d.line((x,90,x-18,120),fill=(48,33,38),width=1)
    for _ in range(180):
        x=rng.randrange(160);y=rng.randrange(120)
        if y>87:
            d.point((x,y),fill=blend(bottom,(164,136,98),rng.random()*.45))
    im.resize((640,480),Image.Resampling.NEAREST).save(
        OUT/('scene_'+which+'.png'))

if __name__=='__main__':
    gladiator()
    armory()
    for monster in ['wolf','pirate','minotaur','gladiator']:
        opponent(monster)
    for place in ['colosseum','forest','port','ruins']:
        scene(place)
    print('Pixel art HD: personagem em camadas, inimigos e cenários exportados!')
