import asyncio, json, sys
from playwright.async_api import async_playwright
async def main(routes):
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html'); await pg.wait_for_timeout(400)
        await pg.click('#tb-frame button[data-f="mobile"]'); await pg.wait_for_timeout(300)
        for r in routes:
            await pg.evaluate("id=>window.mock.nav(id)", r); await pg.wait_for_timeout(300)
            over = await pg.evaluate("""() => {const m=document.querySelector('.main'); if(!m) return null;
              const w=m.clientWidth, bad=[];
              m.querySelectorAll('*').forEach(el=>{const r=el.getBoundingClientRect();
                if(el.scrollWidth>el.clientWidth+2 && el.clientWidth>0) bad.push([el.className||el.tagName, el.scrollWidth, el.clientWidth]);});
              return {mainW:w, mainScroll:m.scrollWidth, bad:bad.slice(0,8)};}""")
            print(r, json.dumps(over, ensure_ascii=False))
            await pg.screenshot(path='shots/m_'+r.replace('/','_')+'.png')
        await b.close()
asyncio.run(main(sys.argv[1].split(',')))
