import asyncio
from playwright.async_api import async_playwright
URL='file:///mnt/user-data/outputs/gamification-hub-mockup.html'
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        errs=[]; pg.on('pageerror', lambda e: errs.append(str(e)))
        await pg.goto(URL); await pg.wait_for_timeout(400)
        await pg.click('#tb-theme button[data-t="dark"]')
        # 1+2 student start
        await pg.evaluate("window.mock.nav('s/start')"); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a1_start.png', clip={'x':0,'y':40,'width':1440,'height':500})
        # 3 join step 1
        await pg.click('.hd-join'); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a3_join1.png', clip={'x':420,'y':240,'width':620,'height':420})
        for i,ch in enumerate('Z4KN7Q'):
            await pg.fill(f'[data-slot="{i}"]', ch)
        await pg.wait_for_timeout(150)
        await pg.click('[data-join]'); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a4_join2.png', clip={'x':420,'y':240,'width':620,'height':420})
        await pg.keyboard.press('Escape')
        # 5 leave dialog
        await pg.evaluate("window.mock.nav('s/group-settings')"); await pg.wait_for_timeout(250)
        await pg.click('[data-act="leave"]'); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a5_leave.png', clip={'x':380,'y':240,'width':700,'height':420})
        await pg.keyboard.press('Escape')
        # 6 notifications
        await pg.evaluate("window.mock.nav('t/dash')"); await pg.wait_for_timeout(250)
        await pg.click('.hd .iconbtn[aria-expanded]'); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a6_notif.png', clip={'x':950,'y':40,'width':490,'height':720})
        await pg.keyboard.press('Escape')
        # 7 teacher home hero
        await pg.evaluate("window.mock.nav('t/home')"); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a7_home.png', clip={'x':280,'y':100,'width':1160,'height':300})
        # 8 grading
        await pg.evaluate("window.mock.nav('t/grade')"); await pg.wait_for_timeout(250)
        await pg.screenshot(path='shots/a8_grade.png')
        # 9 wizard success
        await pg.evaluate("window.mock.nav('t/new-group')"); await pg.wait_for_timeout(250)
        await pg.fill('[data-f="name"]', 'Zakon Algorytmow')
        for _ in range(4):
            await pg.click('[data-act="next"]'); await pg.wait_for_timeout(300)
        await pg.screenshot(path='shots/a9_done.png')
        print('errors:', errs or 'none')
        await b.close()
asyncio.run(main())
