import asyncio
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        errs=[]; pg.on('pageerror', lambda e: errs.append(str(e)))
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html'); await pg.wait_for_timeout(400)
        await pg.click('#tb-theme button[data-t="dark"]')
        # finish the wizard properly
        await pg.evaluate("window.mock.nav('t/new-group')"); await pg.wait_for_timeout(250)
        await pg.fill('[data-f="name"]', 'Zakon Algorytmow')
        await pg.click('[data-act="next"]'); await pg.wait_for_timeout(250)
        for f, v in [('n1','Klejnot'), ('n2','Klejnoty'), ('n5','Klejnotow')]:
            await pg.fill(f'[data-f="{f}"]', v)
        await pg.click('[data-act="next"]'); await pg.wait_for_timeout(250)
        await pg.click('[data-act="next"]'); await pg.wait_for_timeout(250)
        await pg.click('[data-act="next"]'); await pg.wait_for_timeout(400)
        await pg.screenshot(path='shots/b9_done.png')
        # shop (card backs / sealed), student purse stats, teacher students list
        for route, name in [('s/shop','b_shop'), ('s/home','b_home'), ('t/students','b_students'), ('s/my-items','b_items')]:
            await pg.evaluate(f"window.mock.nav('{route}')"); await pg.wait_for_timeout(250)
            await pg.screenshot(path=f'shots/{name}.png')
        print('errors:', errs or 'none')
        await b.close()
asyncio.run(main())
