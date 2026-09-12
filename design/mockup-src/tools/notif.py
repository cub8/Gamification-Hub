import asyncio, json
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html'); await pg.wait_for_timeout(400)
        await pg.evaluate("window.mock.nav('t/dash')"); await pg.wait_for_timeout(250)
        await pg.click('.hd .iconbtn[aria-expanded]'); await pg.wait_for_timeout(300)
        await pg.screenshot(path='shots/n1.png', clip={'x':960,'y':40,'width':480,'height':680})
        info = await pg.evaluate("""() => {const h=document.querySelector('.pop-h'), l=h.querySelector('.linkbtn'), i=l.querySelector('.ic'), f=document.querySelector('.pop-f'), pop=document.querySelector('.pop');
          const r=el=>{const b=el.getBoundingClientRect();return {top:Math.round(b.top),bottom:Math.round(b.bottom),h:Math.round(b.height)};};
          const cs=getComputedStyle(l);
          return {h:r(h), link:r(l), icon:r(i), foot:r(f), pop:r(pop), linkAlign:cs.alignItems, linkDisp:cs.display, popPadB:getComputedStyle(pop).paddingBottom};}""")
        print(json.dumps(info, indent=1))
        await b.close()
asyncio.run(main())
