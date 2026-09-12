import asyncio, json
from playwright.async_api import async_playwright
SEL = "[data-act='award']"
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1280,'height':700})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html'); await pg.wait_for_timeout(400)
        await pg.evaluate("window.mock.nav('t/grade')"); await pg.wait_for_timeout(300)
        for j in [4,5,6,7]:
            await pg.click(f'[data-act="col"][data-j="{j}"]'); await pg.wait_for_timeout(50)
        await pg.click('[data-act="review"]'); await pg.wait_for_timeout(400)
        await pg.screenshot(path='shots/rev3.png')
        info = await pg.evaluate("""() => {const d=document.querySelector('.dlg'), i=document.querySelector('.dlg-in');
          return {dlgH:d.clientHeight, innH:i.clientHeight, innSH:i.scrollHeight, appH:document.getElementById('app').clientHeight};}""")
        print(json.dumps(info))
        await pg.evaluate("document.querySelector('.dlg-in').scrollTop=9999"); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/rev4.png')
        print('award visible:', await pg.is_visible(SEL))
        await pg.click(SEL); await pg.wait_for_timeout(500)
        await pg.screenshot(path='shots/rev5.png')
        print('awarded ok')
        await b.close()
asyncio.run(main())
