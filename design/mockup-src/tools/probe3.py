import asyncio, json
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html')
        await pg.wait_for_timeout(400)
        await pg.evaluate("window.mock.nav('t/grade')"); await pg.wait_for_timeout(300)
        out = await pg.evaluate("""() => {
          const pend=[...document.querySelectorAll('.board .cell.pending, .grid .cell.pending, .cell.pending')].pop();
          const aw=[...document.querySelectorAll('.cell.awarded')].pop();
          const info=el=>{const c=getComputedStyle(el);const pc=getComputedStyle(el.parentElement);
            return {cls:el.className, tag:el.tagName, w:c.width, minW:c.minWidth, disp:c.display, html:el.outerHTML.slice(0,160),
                    parent:{tag:el.parentElement.tagName, cls:el.parentElement.className, disp:pc.display, w:pc.width, ta:pc.textAlign}};};
          return {pend:info(pend), aw:info(aw)};
        }""")
        print(json.dumps(out, indent=1, ensure_ascii=False))
        await b.close()
asyncio.run(main())
