import asyncio, json
from playwright.async_api import async_playwright
TESTS = {
 'baseline': '',
 'dash-min0': '.dash>*{min-width:0}',
 'prow-min0': '.prow>*{min-width:0}',
 'both': '.dash>*{min-width:0}.prow>*{min-width:0}',
 'filters-wrap': '.filters{flex-wrap:wrap}',
}
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page(viewport={'width':1440,'height':940})
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html'); await pg.wait_for_timeout(400)
        await pg.click('#tb-frame button[data-f="mobile"]'); await pg.wait_for_timeout(300)
        await pg.evaluate("window.mock.nav('t/dash')"); await pg.wait_for_timeout(300)
        for name, css in TESTS.items():
            await pg.evaluate("""css=>{let s=document.getElementById('t-css'); if(!s){s=document.createElement('style');s.id='t-css';document.head.appendChild(s);} s.textContent=css;}""", css)
            await pg.wait_for_timeout(150)
            r = await pg.evaluate("""() => {const m=document.querySelector('.main');
              return {mainScroll:m.scrollWidth, purch:Math.round(document.querySelector('.purch').getBoundingClientRect().width)};}""")
            print(f'{name:14}', json.dumps(r))
        await b.close()
asyncio.run(main())
