import sys,json,os
here=os.path.dirname(os.path.abspath(__file__))
src=open(os.path.join(here,'game.html')).read()
cfg=json.load(open(os.path.join(here,'config.json'))) if os.path.exists(os.path.join(here,'config.json')) else {"url":"","key":""}
shim=open(os.path.join(here,'shim.js')).read()
import datetime
ver=datetime.datetime.now().strftime('%Y%m%d-%H%M')   # build stamp, sent with analytics events and problem reports
three='<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>'
assert src.count(three)==1
inject=('<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js"></script>\n'
        f'<script>window.SB_URL={json.dumps(cfg["url"])};window.SB_KEY={json.dumps(cfg["key"])};window.SB_VER={json.dumps(ver)};</script>\n'
        '<script>'+shim+'</script>\n'+three)
body=src.replace(three,inject)
head=('<!doctype html><html lang="zh-Hant"><head><meta charset="utf-8">'
 '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
 '<meta name="theme-color" content="#111a26"><meta name="description" content="秘法雙橋 SPELLBRIDGE：3D 巫師卡牌對戰。">'
 '<meta property="og:title" content="秘法雙橋 SPELLBRIDGE"><meta property="og:description" content="3D 巫師卡牌對戰，100 張元素卡牌、好友即時對戰、公會與雲端存檔。">'
 '<meta property="og:type" content="website"><meta property="og:url" content="https://spellbridge.off-office.co/">'
 '<meta property="og:image" content="https://spellbridge.off-office.co/og.png"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630">'
 '<meta name="twitter:card" content="summary_large_image"><meta name="twitter:image" content="https://spellbridge.off-office.co/og.png">'
 '<link rel="icon" href="icon.svg" type="image/svg+xml"><link rel="icon" href="icon-32.png" sizes="32x32" type="image/png">'
 '<link rel="apple-touch-icon" href="apple-touch-icon.png"><meta name="apple-mobile-web-app-title" content="秘法雙橋">'
 '<style>body{margin:0;font:14px system-ui,sans-serif}img{max-width:100%}[hidden]{display:none!important}</style>'
 '</head><body>')
open(os.path.join(here,'..','index.html'),'w').write(head+body+'</body></html>')
print('built',len(head+body))
# admin dashboard: same public Supabase URL/key; data access is gated by RLS + admin_stats()
adm=open(os.path.join(here,'admin.html')).read().replace('__SB_URL__',cfg['url']).replace('__SB_KEY__',cfg['key'])
open(os.path.join(here,'..','admin.html'),'w').write(adm)
print('built admin',len(adm))
