/**
 * The customer's browser lands here after the hosted gateway page, so this is
 * the only part of the payment flow they actually read. It must be a real page:
 * returning the usual JSON envelope made a successful payment look broken.
 *
 * Self-contained HTML — no CDN, no build step, works offline of the storefront.
 */

type Outcome = 'paid' | 'failed' | 'pending' | 'error';

const escapeHtml = (value: string) =>
  value.replace(
    /[&<>"']/g,
    (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c] as string,
  );

const COPY: Record<Outcome, { title: string; body: string; glyph: string; color: string }> = {
  paid: {
    title: 'تم الدفع بنجاح',
    body: 'استلمنا مبلغ طلبك، وسيبدأ التجهيز فوراً.',
    glyph: '&#10003;',
    color: '#43C46A',
  },
  failed: {
    title: 'لم تكتمل عملية الدفع',
    body: 'لم يُخصم أي مبلغ من بطاقتك. يمكنك المحاولة مرة أخرى من داخل التطبيق.',
    glyph: '&#10005;',
    color: '#E05B5B',
  },
  pending: {
    title: 'جارٍ تأكيد الدفع',
    body: 'لم يصلنا تأكيد البنك بعد. سيتحدّث الطلب تلقائياً خلال دقائق، ويمكنك متابعته من «طلباتي».',
    glyph: '&#8230;',
    color: '#CFA347',
  },
  error: {
    title: 'تعذّر عرض حالة الدفع',
    body: 'إن كنت قد أتممت الدفع فسيظهر الطلب في «طلباتي» خلال دقائق. للاستفسار تواصل معنا.',
    glyph: '!',
    color: '#CFA347',
  },
};

export function renderPaymentResult(outcome: Outcome, orderNumber?: string): string {
  const { title, body, glyph, color } = COPY[outcome];
  const reference = orderNumber
    ? `<p class="ref">رقم الطلب<span dir="ltr">${escapeHtml(orderNumber)}</span></p>`
    : '';

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${title} — الضيافة</title>
<style>
  :root { color-scheme: light; }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
    padding: 24px; background: #0E2A1B; color: #0E2A1B;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Cairo", "Tahoma", sans-serif;
  }
  .card {
    width: 100%; max-width: 420px; background: #FFF8E7; border-radius: 24px;
    padding: 40px 28px 32px; text-align: center; box-shadow: 0 18px 50px rgba(0,0,0,.35);
  }
  .badge {
    width: 76px; height: 76px; margin: 0 auto 22px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 38px; line-height: 1; color: #fff; background: ${color};
  }
  h1 { margin: 0 0 12px; font-size: 22px; font-weight: 700; }
  p  { margin: 0; font-size: 15px; line-height: 1.85; color: #4A5A50; }
  .ref {
    margin-top: 22px; padding-top: 18px; border-top: 1px solid rgba(14,42,27,.12);
    font-size: 14px; color: #0E2A1B; font-weight: 600;
  }
  .ref span { display: block; margin-top: 6px; font-size: 17px; letter-spacing: .5px; }
  .hint { margin-top: 26px; font-size: 13px; color: #8A968F; }
</style>
</head>
<body>
  <main class="card">
    <div class="badge">${glyph}</div>
    <h1>${title}</h1>
    <p>${body}</p>
    ${reference}
    <p class="hint">يمكنك إغلاق هذه الصفحة والعودة إلى تطبيق الضيافة.</p>
  </main>
</body>
</html>`;
}
