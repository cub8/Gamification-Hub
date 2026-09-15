import asyncio, json
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html'); await pg.wait_for_timeout(400)
        await pg.click('#tb-frame button[data-f="mobile"]'); await pg.wait_for_timeout(300)
        await pg.evaluate("window.mock.nav('t/dash')"); await pg.wait_for_timeout(300)
        out = await pg.evaluate("""() => {
          const wide=[]; const main=document.querySelector('.main');
          main.querySelectorAll('*').forEach(el=>{const r=el.getBoundingClientRect();
            if(r.width>370) wide.push({cls:(el.className||el.tagName).toString().slice(0,40), w:Math.round(r.width), minW:getComputedStyle(el).minWidth, disp:getComputedStyle(el).display, cols:getComputedStyle(el).gridTemplateColumns});});
          return wide.slice(0,14);}""")
        print(json.dumps(out, indent=1, ensure_ascii=False))
        await b.close()
asyncio.run(main())
