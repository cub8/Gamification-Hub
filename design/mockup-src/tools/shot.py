import sys, asyncio, pathlib
from playwright.async_api import async_playwright
URL='file:///mnt/user-data/outputs/gamification-hub-mockup.html'
async def main(routes, theme='light', frame='desktop', prefix='', clicks=None):
    async with async_playwright() as p:
        b=await p.chromium.launch()
        pg=await b.new_page(viewport={'width':1440,'height':940})
        errs=[]
        pg.on('console', lambda m: errs.append(m.type+': '+m.text) if m.type=='error' else None)
        pg.on('pageerror', lambda e: errs.append('pageerror: '+str(e)))
        await pg.goto(URL)
        await pg.wait_for_timeout(400)
        if theme=='dark': await pg.click('#tb-theme button[data-t="dark"]')
        if frame=='mobile': await pg.click('#tb-frame button[data-f="mobile"]')
        for r in routes:
            await pg.evaluate("id=>window.mock.nav(id)", r)
            await pg.wait_for_timeout(250)
            name=prefix+r.replace('/','_')+('_'+theme if theme!='light' else '')+('_m' if frame=='mobile' else '')
            await pg.screenshot(path=f'shots/{name}.png')
        await b.close()
        print('ERRORS:' if errs else 'no console errors')
        for e in dict.fromkeys(errs): print(' ', e[:300])
routes=sys.argv[1].split(',')
theme=sys.argv[2] if len(sys.argv)>2 else 'light'
frame=sys.argv[3] if len(sys.argv)>3 else 'desktop'
asyncio.run(main(routes, theme, frame))
