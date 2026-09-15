import asyncio
from playwright.async_api import async_playwright
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(); pg=await b.new_page()
        errs=[]
        pg.on('pageerror', lambda e: errs.append(str(e)))
        pg.on('console', lambda m: errs.append(m.type+': '+m.text) if m.type=='error' else None)
        await pg.goto('file:///mnt/user-data/outputs/gamification-hub-mockup.html')
        await pg.wait_for_timeout(500)
        print('\n'.join(errs[:10]) or 'clean')
        await b.close()
asyncio.run(main())
