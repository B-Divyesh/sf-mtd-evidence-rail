import assert from 'node:assert/strict';

// @claim:hosted-checkout

const productSlug = 'mtd-evidence-rail';
const productId = 'pdt_0NmPnl9rqkKtKbVXh6baV';
const endpoint = `https://api.sociobot.in/api/v1/products/${productSlug}/checkout`;

const response = await fetch(endpoint, { redirect: 'manual' });
assert.ok(
  [301, 302, 303, 307, 308].includes(response.status),
  `Expected ${endpoint} to redirect, received HTTP ${response.status}`,
);

const checkoutUrl = response.headers.get('location');
assert.ok(checkoutUrl, 'Checkout response did not include a Location header');
const hosted = new URL(checkoutUrl);
assert.equal(hosted.protocol, 'https:', 'Checkout must use HTTPS');
assert.equal(hosted.hostname, 'checkout.dodopayments.com', 'Checkout must be hosted by Dodo');
assert.ok(hosted.pathname.startsWith('/session/'), 'Checkout must point to a Dodo checkout session');

const checkout = await fetch(hosted, { redirect: 'error' });
assert.equal(checkout.status, 200, `Dodo checkout returned HTTP ${checkout.status}`);
const page = await checkout.text();
// Next streams the checkout session through a JSON-escaped React payload.
const contractPage = page.replaceAll('\\"', '"');

function includes(contract, explanation) {
  assert.ok(contractPage.includes(contract), `${explanation}; missing ${contract}`);
}

includes(`"product_id":"${productId}"`, 'Wrong Dodo product mapping');
includes(`"product_slug":"${productSlug}"`, 'Wrong product slug in Dodo checkout metadata');
includes('"session_type":"subscription"', 'Checkout is not a subscription session');
includes('"is_recurring":true', 'Dodo product is not recurring');
includes('"price":1500,"currency":"GBP"', 'Product price is not GBP 1500');
includes('"payment_frequency_count":1,"payment_frequency_interval":"Month"', 'Payment cadence is not monthly');
includes('"subscription_period_count":1,"subscription_period_interval":"Month"', 'Subscription period is not monthly');

console.log(JSON.stringify({
  claim: 'hosted-checkout',
  endpoint,
  status: response.status,
  hosted_checkout: `${hosted.origin}${hosted.pathname}`,
  product_slug: productSlug,
  product_id: productId,
  amount_minor: 1500,
  currency: 'GBP',
  cadence: 'monthly',
}, null, 2));
