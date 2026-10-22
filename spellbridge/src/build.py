import sys,json,os
here=os.path.dirname(os.path.abspath(__file__))
src=open(os.path.join(here,'game.html')).read()
cfg=json.load(open(os.path.join(here,'config.json'))) if os.path.exists(os.path.join(here,'config.json')) else {"url":"","key":""}
shim=open(os.path.join(here,'shim.js')).read()
three='<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>'
assert src.count(three)==1
inject=('<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js"></script>\n'
        f'<script>window.SB_URL={json.dumps(cfg["url"])};window.SB_KEY={json.dumps(cfg["key"])};</script>\n'
        '<script>'+shim+'</script>\n'+three)
body=src.replace(three,inject)
head=('<!doctype html><html lang="zh-Hant"><head><meta charset="utf-8">'
 '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
 '<meta name="theme-color" content="#111a26"><meta name="description" content="秘法雙橋 SPELLBRIDGE：3D 巫師卡牌對戰。">'
 '<meta property="og:title" content="秘法雙橋 SPELLBRIDGE"><meta property="og:description" content="3D 巫師卡牌對戰，100 張元素卡牌、好友即時對戰、公會與雲端存檔。">'
 '<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22%3E%3Cpath fill=%22%23b65cf0%22 d=%22M12 1l10 11-10 11L2 12z%22/%3E%3Cpath fill=%22%23f3c55b%22 d=%22M12 6l5 6-5 6-5-6z%22/%3E%3C/svg%3E">'
 '<style>body{margin:0;font:14px system-ui,sans-serif}img{max-width:100%}[hidden]{display:none!important}</style>'
 '</head><body>')
open(os.path.join(here,'..','index.html'),'w').write(head+body+'</body></html>')
print('built',len(head+body))
