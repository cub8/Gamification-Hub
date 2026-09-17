import asyncio, json
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html')
        await pg.wait_for_timeout(400)
        await pg.click('#tb-theme button[data-t="dark"]')
        await pg.evaluate("window.mock.nav('t/grade')")
        await pg.wait_for_timeout(300)
        await pg.screenshot(path='shots/fix_grade.png')
        out = await pg.evaluate("""() => {
          const c0=document.querySelector('.cell'), cm=document.querySelector('.cell.on')||document.querySelector('.cell[data-on]');
          const cells=[...document.querySelectorAll('.cell')].slice(0,6).map(c=>({cls:c.className, w:Math.round(c.getBoundingClientRect().width), h:Math.round(c.getBoundingClientRect().height)}));
          const tot=document.querySelector('.tot')||document.querySelector('.rsum');
          return {cells, totCls: tot?tot.className:null, totHTML: tot?tot.outerHTML.slice(0,200):null};
        }""")
        print(json.dumps(out, indent=1, ensure_ascii=False))
        # notifications
        await pg.evaluate("window.mock.nav('t/dash')"); await pg.wait_for_timeout(200)
        await pg.click('.hd .iconbtn[aria-expanded]'); await pg.wait_for_timeout(300)
        await pg.screenshot(path='shots/fix_notif.png')
        n = await pg.evaluate("""() => {const w=document.querySelector('.pop-w'), li=document.querySelector('.nlist li button');
          return {popW: w?Math.round(w.getBoundingClientRect().width):null, popCS:w?getComputedStyle(w).width:null,
                  liDisp: li?getComputedStyle(li).display:null, liCols: li?getComputedStyle(li).gridTemplateColumns:null, liHTML: li?li.outerHTML.slice(0,300):null};}""")
        print(json.dumps(n, indent=1, ensure_ascii=False))
        await b.close()
asyncio.run(main())
