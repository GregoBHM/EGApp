const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    console.log('Navigating...');
    await page.goto('https://dniperu.com/buscar-dni-nombres-apellidos/', { waitUntil: 'domcontentloaded', timeout: 15000 });
    console.log('Filling...');
    await page.fill('#cc_nombres_1dni', '77436156');
    await page.click('.js-cc-submit');
    console.log('Waiting for result...');
    await page.waitForSelector('.js-cc-copy-source', { state: 'visible', timeout: 10000 });
    const text = await page.inputValue('.js-cc-copy-source');
    console.log('Result:', text);
  } catch (err) {
    console.error('Error:', err.message);
    await page.screenshot({ path: 'error.png', fullPage: true });
  } finally {
    await browser.close();
  }
})();
