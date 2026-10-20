from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path('assets/sprites')
OUT.mkdir(parents=True, exist_ok=True)

INK=(24,17,18,255)
GOLD=(230,185,65,255)
SILVER=(196,209,225,255)
LIGHT=(246,247,250,255)
RED=(183,38,51,255)
DARKRED=(107,22,32,255)
SKIN=(215,164,107,255)
SHADOW=(145,98,64,255)
BROWN=(105,66,44,255)

def canvas(w=32,h=36):
    return Image.new('RGBA',(w,h),(0,0,0,0))

def block(img,xy,colour):
    ImageDraw.Draw(img).rectangle(xy,fill=colour)

def px(img,x,y,c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x,y),c)

def outline(im):
    original=im.copy()
    for y in range(im.height):
        for x in range(im.width):
            if original.getpixel((x,y))[3]: continue
            if any(0<=xx<im.width and 0<=yy<im.height and original.getpixel((xx,yy))[3] for xx,yy in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]):
                im.putpixel((x,y),INK)
    return im

def save(name, im):
    outline(im).save(OUT/(name+'.png'))

def gladiator():
    im=canvas()
    block(im,(8,32,24,33),(0,0,0,90))
    for x in (11,17):
        block(im,(x,21,x+3,31),SHADOW)
        block(im,(x,22,x+1,29),SKIN)
        block(im,(x-1,28,x+4,32),BROWN)
        px(im,x,29,GOLD)
    block(im,(10,12,21,21),SHADOW)
    block(im,(11,12,19,16),SKIN)
    block(im,(14,15,15,21),SHADOW)
    for y in (16,19):
        px(im,13,y,SHADOW);px(im,18,y,SHADOW)
    block(im,(9,19,22,22),BROWN)
    block(im,(14,19,17,21),GOLD)
    block(im,(7,12,9,20),SKIN)
    block(im,(22,12,24,20),SHADOW)
    block(im,(7,18,9,19),BROWN)
    block(im,(22,18,24,19),BROWN)
    block(im,(12,4,19,11),SKIN)
    block(im,(18,5,19,11),SHADOW)
    block(im,(12,3,19,5),BROWN)
    px(im,14,8,INK);px(im,18,8,INK)
    save('gladiator_base',im)

def helmet():
    im=canvas()
    block(im,(13,0,19,2),RED)
    block(im,(17,1,19,2),DARKRED)
    block(im,(11,3,21,7),GOLD)
    block(im,(12,4,16,5),LIGHT)
    block(im,(11,7,13,11),BROWN)
    block(im,(19,7,21,11),BROWN)
    px(im,16,5,SILVER)
    save('equip_helmet',im)

def armor():
    im=canvas()
    block(im,(9,11,22,22),DARKRED)
    for y in (11,14,17):
        block(im,(10,y,21,y+2),SILVER)
        block(im,(11,y,16,y),LIGHT)
        block(im,(19,y,21,y+2),(111,125,146,255))
    block(im,(7,10,10,14),SILVER)
    block(im,(21,10,24,14),SILVER)
    px(im,8,11,GOLD);px(im,22,11,GOLD)
    save('equip_armor',im)

def weapon():
    im=canvas()
    block(im,(5,5,7,16),SILVER)
    block(im,(5,5,5,15),LIGHT)
    px(im,6,4,LIGHT)
    block(im,(3,16,9,17),GOLD)
    block(im,(5,18,7,21),BROWN)
    px(im,6,21,GOLD)
    save('equip_weapon',im)

def shield():
    im=canvas()
    block(im,(21,10,30,26),GOLD)
    block(im,(22,11,29,25),RED)
    block(im,(27,11,29,25),DARKRED)
    block(im,(24,16,27,20),GOLD)
    for x,y in [(24,14),(27,14),(24,22),(27,22)]:
        px(im,x,y,GOLD)
    save('equip_shield',im)

def icons():
    names=['weapon','shield','helmet','armor','gloves','boots','ring','amulet']
    for name in names:
        im=canvas(24,24)
        if name=='weapon':
            for i in range(12):
                block(im,(5+i,16-i,7+i,17-i),SILVER)
                px(im,6+i,16-i,LIGHT)
            block(im,(4,16,10,18),GOLD);block(im,(3,19,5,21),BROWN)
        elif name=='shield':
            block(im,(5,3,18,19),GOLD)
            block(im,(7,4,16,17),RED)
            block(im,(10,9,13,13),GOLD)
            block(im,(9,18,14,21),GOLD)
        elif name=='helmet':
            block(im,(8,2,16,5),RED)
            block(im,(5,6,19,18),GOLD)
            block(im,(8,11,16,18),INK)
            block(im,(11,10,13,18),GOLD)
        elif name=='armor':
            block(im,(5,5,18,20),SILVER)
            block(im,(3,6,6,10),SILVER)
            block(im,(18,6,21,10),SILVER)
            for y in (8,11,14,17):
                block(im,(7,y,16,y),LIGHT)
        elif name=='ring':
            block(im,(7,8,17,18),GOLD)
            block(im,(10,11,14,15),(0,0,0,0))
            block(im,(10,5,14,9),(206,52,80,255))
            px(im,11,5,LIGHT)
        elif name=='amulet':
            block(im,(11,3,12,7),SILVER)
            block(im,(7,8,16,19),GOLD)
            block(im,(9,10,14,16),(59,152,196,255))
            px(im,10,11,LIGHT)
        elif name=='gloves':
            block(im,(7,5,10,15),BROWN)
            block(im,(13,5,17,15),BROWN)
            block(im,(7,14,11,20),GOLD)
            block(im,(13,14,17,20),GOLD)
        else:
            block(im,(5,4,10,19),BROWN)
            block(im,(13,4,18,19),BROWN)
            block(im,(4,17,11,21),GOLD)
            block(im,(12,17,20,21),GOLD)
        save('icon_'+name,im)

def enemies():
    variants={
      'wolf':((110,120,134,255),(70,77,89,255)),
      'pirate':((175,79,58,255),(78,45,37,255)),
      'minotaur':((153,92,55,255),(91,48,29,255)),
      'gladiator':((185,161,83,255),(144,32,43,255))}
    for name,(main,shade) in variants.items():
        im=canvas(32,32)
        block(im,(7,28,25,29),(0,0,0,95))
        block(im,(10,11,22,23),main)
        block(im,(17,12,22,23),shade)
        block(im,(10,22,14,28),shade)
        block(im,(18,22,22,28),shade)
        block(im,(11,4,21,12),main)
        if name in ('minotaur','wolf'):
            block(im,(8,3,11,8),shade)
            block(im,(21,3,24,8),shade)
            if name=='minotaur':
                block(im,(7,2,9,4),GOLD);block(im,(23,2,25,4),GOLD)
        elif name=='pirate':
            block(im,(10,3,22,5),DARKRED)
            block(im,(18,4,23,7),DARKRED)
            block(im,(3,15,5,25),BROWN)
            block(im,(2,14,7,15),SILVER)
        else:
            block(im,(11,2,21,5),SILVER)
            block(im,(7,12,10,18),SILVER)
            block(im,(22,12,25,18),SILVER)
            block(im,(2,13,6,20),SILVER)
        px(im,13,8,RED)
        px(im,18,8,RED)
        if name=='wolf':
            block(im,(11,12,21,15),shade)
            block(im,(11,16,12,18),LIGHT)
            block(im,(20,16,21,18),LIGHT)
        save('enemy_'+name,im)

if __name__=='__main__':
    gladiator();helmet();armor();weapon();shield();icons();enemies()
    print('17 PNGs exportados para assets/sprites/')
