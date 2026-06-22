const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    console.log('Navigating to eldni.com...');
    await page.goto('https://eldni.com/buscar-por-dni', { waitUntil: 'domcontentloaded', timeout: 15000 });
    console.log('Filling...');
    await page.fill('#dni', '77436156');
    await page.click('#btn-buscar');
    console.log('Waiting for result...');
    await page.waitForSelector('table', { state: 'visible', timeout: 10000 });
    const text = await page.innerText('table');
    console.log('Result:', text);
  } catch (err) {
    console.error('Error:', err.message);
    await page.screenshot({ path: 'error_eldni.png', fullPage: true });
  } finally {
    await browser.close();
  }
})();
