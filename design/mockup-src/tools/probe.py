import asyncio, sys, json
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html')
        await pg.wait_for_timeout(400)
        await pg.evaluate("window.mock.nav('s/start')")
        await pg.wait_for_timeout(200)
        await pg.click('.hd-join')
        await pg.wait_for_timeout(300)
        out = await pg.evaluate("""() => [...document.querySelectorAll('.dlg-b .btn')].map(b=>{
          const r=b.getBoundingClientRect(), c=getComputedStyle(b);
          return {t:b.textContent.trim(), w:Math.round(r.width), h:Math.round(r.height),
            font:c.font, pad:c.padding, minH:c.minHeight, disp:c.display, align:c.alignItems, fs:c.fontSize, lh:c.lineHeight};})""")
        print(json.dumps(out, indent=1, ensure_ascii=False))
        cs = await pg.evaluate("""() => {const d=document.querySelector('.dlg-b'); const c=getComputedStyle(d); return {disp:c.display, align:c.alignItems, gap:c.gap, just:c.justifyContent};}""")
        print(cs)
        await b.close()
asyncio.run(main())
