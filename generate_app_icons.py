import os
import math
from PIL import Image, ImageDraw

def create_rounded_rect_mask(size, radius):
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size[0], size[1]], radius=radius, fill=255)
    return mask

def make_gradient(size, start_color, end_color):
    base = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)
    w, h = size
    for y in range(h):
        r = int(start_color[0] + (end_color[0] - start_color[0]) * (y / h))
        g = int(start_color[1] + (end_color[1] - start_color[1]) * (y / h))
        b = int(start_color[2] + (end_color[2] - start_color[2]) * (y / h))
        a = 255
        draw.line([(0, y), (w, y)], fill=(r, g, b, a))
    return base

def draw_aarogya_patient(size=(1024, 1024)):
    img = make_gradient(size, (15, 118, 110), (13, 148, 136))
    mask = create_rounded_rect_mask(size, 220)
    
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([20, 20, size[0]-20, size[1]-20], radius=210, outline=(45, 212, 191, 140), width=16)
    
    # Draw Medical Cross
    cx, cy = size[0] // 2, size[1] // 2 - 20
    cross_w = 140
    cross_l = 440
    r = 50
    # vertical bar
    draw.rounded_rectangle([cx - cross_w//2, cy - cross_l//2, cx + cross_w//2, cy + cross_l//2], radius=r, fill=(255, 255, 255, 255))
    # horizontal bar
    draw.rounded_rectangle([cx - cross_l//2, cy - cross_w//2, cx + cross_l//2, cy + cross_w//2], radius=r, fill=(255, 255, 255, 255))
    
    # Pulse wave in mint/gold overlay across center
    pulse_pts = [
        (cx - 360, cy),
        (cx - 180, cy),
        (cx - 120, cy - 90),
        (cx - 60, cy + 110),
        (cx + 10, cy - 140),
        (cx + 80, cy + 90),
        (cx + 140, cy),
        (cx + 360, cy)
    ]
    draw.line(pulse_pts, fill=(16, 185, 129, 255), width=28, joint="round")
    draw.line(pulse_pts, fill=(255, 255, 255, 220), width=12, joint="round")
    
    # Pulse nodes
    for px, py in [(cx - 120, cy - 90), (cx - 60, cy + 110), (cx + 10, cy - 140), (cx + 80, cy + 90)]:
        draw.ellipse([px-14, py-14, px+14, py+14], fill=(255, 255, 255, 255))
    
    # Subtitle dot
    draw.ellipse([cx-12, size[1]-130, cx+12, size[1]-106], fill=(45, 212, 191, 230))
    
    # Apply squircle mask
    result = Image.new('RGBA', size, (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result

def draw_aarogya_doctor(size=(1024, 1024)):
    img = make_gradient(size, (67, 56, 202), (14, 116, 144))
    mask = create_rounded_rect_mask(size, 220)
    
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([20, 20, size[0]-20, size[1]-20], radius=210, outline=(129, 140, 248, 140), width=16)
    
    cx, cy = size[0] // 2, size[1] // 2 - 20
    
    # Stethoscope loop
    draw.arc([cx - 240, cy - 240, cx + 240, cy + 180], start=0, end=180, fill=(255, 255, 255, 255), width=32)
    # Stethoscope earpieces
    draw.line([(cx - 240, cy - 30), (cx - 240, cy - 200), (cx - 160, cy - 270)], fill=(255, 255, 255, 255), width=30)
    draw.line([(cx + 240, cy - 30), (cx + 240, cy - 200), (cx + 160, cy - 270)], fill=(255, 255, 255, 255), width=30)
    draw.ellipse([cx - 180, cy - 290, cx - 140, cy - 250], fill=(56, 189, 248, 255))
    draw.ellipse([cx + 140, cy - 290, cx + 180, cy - 250], fill=(56, 189, 248, 255))
    
    # Chestpiece at center bottom
    draw.line([(cx, cy + 180), (cx, cy + 280)], fill=(255, 255, 255, 255), width=32)
    draw.ellipse([cx - 65, cy + 240, cx + 65, cy + 370], fill=(255, 255, 255, 255))
    draw.ellipse([cx - 45, cy + 260, cx + 45, cy + 350], fill=(56, 189, 248, 255))
    
    # Central clinical cross
    cross_w = 70
    cross_l = 220
    draw.rounded_rectangle([cx - cross_w//2, cy - cross_l//2 - 10, cx + cross_w//2, cy + cross_l//2 - 10], radius=24, fill=(56, 189, 248, 255))
    draw.rounded_rectangle([cx - cross_l//2, cy - cross_w//2 - 10, cx + cross_l//2, cy - cross_w//2 + cross_w - 10], radius=24, fill=(56, 189, 248, 255))
    
    result = Image.new('RGBA', size, (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result

def draw_aarogya_rapid(size=(1024, 1024)):
    img = make_gradient(size, (220, 38, 38), (217, 119, 6))
    mask = create_rounded_rect_mask(size, 220)
    
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([20, 20, size[0]-20, size[1]-20], radius=210, outline=(252, 165, 165, 140), width=16)
    
    cx, cy = size[0] // 2, size[1] // 2 - 20
    
    # 6-pointed Star of life bars
    for angle in [0, 60, 120]:
        rad = math.radians(angle)
        cos_a = math.cos(rad)
        sin_a = math.sin(rad)
        
        # Draw rotated rectangle via polygon
        w, l = 120, 460
        hw, hl = w/2, l/2
        corners = [
            (-hw, -hl), (hw, -hl), (hw, hl), (-hw, hl)
        ]
        rot_corners = [
            (cx + x*cos_a - y*sin_a, cy + x*sin_a + y*cos_a) for x, y in corners
        ]
        draw.polygon(rot_corners, fill=(255, 255, 255, 255))
        
    # Central rapid lightning bolt in amber
    bolt_pts = [
        (cx + 40, cy - 240),
        (cx - 70, cy - 20),
        (cx + 10, cy - 20),
        (cx - 40, cy + 240),
        (cx + 80, cy + 10),
        (cx + 10, cy + 10),
    ]
    draw.polygon(bolt_pts, fill=(245, 158, 11, 255))
    draw.line(bolt_pts + [bolt_pts[0]], fill=(255, 255, 255, 255), width=10)
    
    result = Image.new('RGBA', size, (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result

def draw_aarogya_superadmin(size=(1024, 1024)):
    img = make_gradient(size, (15, 23, 42), (30, 41, 59))
    mask = create_rounded_rect_mask(size, 220)
    
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([20, 20, size[0]-20, size[1]-20], radius=210, outline=(51, 65, 85, 160), width=16)
    
    cx, cy = size[0] // 2, size[1] // 2 - 20
    
    # Outer shield polygon
    shield_pts = [
        (cx - 240, cy - 200),
        (cx + 240, cy - 200),
        (cx + 240, cy + 60),
        (cx, cy + 270),
        (cx - 240, cy + 60),
    ]
    draw.polygon(shield_pts, outline=(16, 185, 129, 255), width=24, fill=(15, 23, 42, 200))
    
    # Inner command cross
    cross_w = 90
    cross_l = 260
    draw.rounded_rectangle([cx - cross_w//2, cy - cross_l//2, cx + cross_w//2, cy + cross_l//2], radius=20, fill=(16, 185, 129, 255))
    draw.rounded_rectangle([cx - cross_l//2, cy - cross_w//2, cx + cross_l//2, cy + cross_w//2], radius=20, fill=(16, 185, 129, 255))
    
    # Glowing center core
    draw.ellipse([cx - 45, cy - 45, cx + 45, cy + 45], fill=(255, 255, 255, 255))
    draw.ellipse([cx - 25, cy - 25, cx + 25, cy + 25], fill=(245, 158, 11, 255))
    
    result = Image.new('RGBA', size, (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result

def export_all():
    apps = [
        ('aarogya', draw_aarogya_patient),
        ('aarogya_healthpro', draw_aarogya_doctor),
        ('aarogya_rapid', draw_aarogya_rapid),
        ('aarogya_superadmin', draw_aarogya_superadmin),
    ]
    
    densities = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    for app_name, draw_fn in apps:
        print(f"Generating icons for {app_name}...")
        img_1024 = draw_fn((1024, 1024))
        
        # Save master asset
        asset_dir = os.path.join(app_name, 'assets', 'images')
        os.makedirs(asset_dir, exist_ok=True)
        img_512 = img_1024.resize((512, 512), Image.Resampling.LANCZOS)
        img_512.save(os.path.join(asset_dir, 'app_logo.png'), 'PNG')
        
        # Save android mipmaps
        for folder, sz in densities.items():
            res_dir = os.path.join(app_name, 'android', 'app', 'src', 'main', 'res', folder)
            os.makedirs(res_dir, exist_ok=True)
            icon = img_1024.resize((sz, sz), Image.Resampling.LANCZOS)
            icon.save(os.path.join(res_dir, 'ic_launcher.png'), 'PNG')
            
    print("All app icons successfully generated!")

if __name__ == '__main__':
    export_all()
