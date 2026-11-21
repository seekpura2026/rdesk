#!/bin/bash
# 去特征化补丁 —— CI 与本地通用
set -e
NEW_ID="${APP_ID:-com.sg.rcpt}"
NEW_NAME="${APP_NAME:-RCPT}"
NEW_LIB="${LIB_NAME:-rcptcore}"

# 1. 包名
sed -i "s|applicationId \"com.carriez.flutter_hbb\"|applicationId \"$NEW_ID\"|" flutter/android/app/build.gradle

# 2. 应用名
sed -i "s|android:label=\"RustDesk\"|android:label=\"$NEW_NAME\"|g" flutter/android/app/src/main/AndroidManifest.xml
sed -i "s|android:label=\"RustDesk Input\"|android:label=\"$NEW_NAME Input\"|g" flutter/android/app/src/main/AndroidManifest.xml

# 3. Rust 库名（改变 so 名与符号布局）
sed -i "s|^name = \"librustdesk\"|name = \"$NEW_LIB\"|" Cargo.toml

# 4. Dart 侧加载名
sed -i "s|librustdesk|lib${NEW_LIB}|g" flutter/lib/models/native_model.dart

# 5. 内部常量
sed -i "s|RwLock::new(\"RustDesk\".to_owned())|RwLock::new(\"$NEW_NAME\".to_owned())|" libs/hbb_common/src/config.rs

# 6. 图标
python3 - "$NEW_NAME" <<'PY'
import sys, os
from PIL import Image, ImageDraw
BASE="flutter/android/app/src/main/res"
def mk(size, rnd=False):
    s=size*4
    im=Image.new("RGBA",(s,s),(0,0,0,0)); d=ImageDraw.Draw(im)
    bg=(16,68,92,255); ac=(64,196,176,255)
    if rnd: d.ellipse([0,0,s-1,s-1],fill=bg)
    else: d.rounded_rectangle([0,0,s-1,s-1],radius=int(s*0.22),fill=bg)
    m=s*0.24; lw=max(2,int(s*0.075))
    d.rounded_rectangle([m,m,s-m,s-m],radius=int(s*0.10),outline=ac,width=lw)
    d.line([s*0.36,s*0.64,s*0.64,s*0.36],fill=ac,width=lw)
    return im.resize((size,size),Image.LANCZOS)
for f,px in {"mipmap-mdpi":48,"mipmap-hdpi":72,"mipmap-xhdpi":96,"mipmap-xxhdpi":144,"mipmap-xxxhdpi":192}.items():
    p=os.path.join(BASE,f)
    if not os.path.isdir(p): continue
    mk(px).save(os.path.join(p,"ic_launcher.png"))
    mk(px,True).save(os.path.join(p,"ic_launcher_round.png"))
    fg=Image.new("RGBA",(px,px),(0,0,0,0)); inn=mk(int(px*0.62))
    o=(px-inn.width)//2; fg.paste(inn,(o,o),inn); fg.save(os.path.join(p,"ic_launcher_foreground.png"))
    st=os.path.join(p,"ic_stat_logo.png")
    if os.path.exists(st):
        im=Image.new("RGBA",(px//2,px//2),(0,0,0,0)); d=ImageDraw.Draw(im)
        q=px//2; m=int(q*0.18); lw=max(1,int(q*0.13))
        d.rounded_rectangle([m,m,q-m,q-m],radius=int(q*0.2),outline=(255,255,255,255),width=lw)
        d.line([q*0.38,q*0.62,q*0.62,q*0.38],fill=(255,255,255,255),width=lw)
        im.save(st)
print("icons regenerated")
PY

echo "patch applied: $NEW_ID / $NEW_NAME / $NEW_LIB"
