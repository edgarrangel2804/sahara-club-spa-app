// Edge Function — checkout-result
// Serves a simple HTML page after Stripe redirects (success or cancel).
// JWT verification DISABLED — Stripe redirects don't carry auth headers.

const successHtml = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pago completado &middot; Sahara Club Spa</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0a0a0a;
      color: #f5f5f0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 32px 24px;
      text-align: center;
    }
    .icon {
      width: 72px; height: 72px;
      border-radius: 50%;
      background: rgba(193,152,78,0.12);
      border: 1px solid rgba(193,152,78,0.3);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 24px;
      font-size: 32px;
    }
    h1 {
      font-size: 24px;
      font-weight: 300;
      letter-spacing: 0.5px;
      margin-bottom: 12px;
      color: #f5f5f0;
    }
    p {
      font-size: 14px;
      color: #888;
      line-height: 1.7;
      max-width: 300px;
    }
    .gold { color: #c1984e; }
    .divider {
      width: 40px; height: 1px;
      background: rgba(193,152,78,0.3);
      margin: 24px auto;
    }
    .label {
      font-size: 10px;
      letter-spacing: 3px;
      color: rgba(193,152,78,0.6);
      text-transform: uppercase;
    }
  </style>
</head>
<body>
  <div>
    <div class="icon">&#10003;</div>
    <div class="label">Sahara Club Spa</div>
    <div class="divider"></div>
    <h1>&iexcl;Pago completado!</h1>
    <p>Tu pedido ha sido confirmado.<br>
    Recibir&aacute;s un correo con los detalles.<br><br>
    <span class="gold">Regresa a la app para ver tu membrec&iacute;a.</span></p>
  </div>
</body>
</html>`;

const cancelHtml = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pago cancelado &middot; Sahara Club Spa</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0a0a0a;
      color: #f5f5f0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 32px 24px;
      text-align: center;
    }
    .icon {
      width: 72px; height: 72px;
      border-radius: 50%;
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.08);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 24px;
      font-size: 28px;
      color: #666;
    }
    h1 {
      font-size: 24px;
      font-weight: 300;
      letter-spacing: 0.5px;
      margin-bottom: 12px;
      color: #f5f5f0;
    }
    p {
      font-size: 14px;
      color: #888;
      line-height: 1.7;
      max-width: 300px;
    }
    .divider {
      width: 40px; height: 1px;
      background: rgba(255,255,255,0.08);
      margin: 24px auto;
    }
    .label {
      font-size: 10px;
      letter-spacing: 3px;
      color: rgba(193,152,78,0.6);
      text-transform: uppercase;
    }
  </style>
</head>
<body>
  <div>
    <div class="icon">&times;</div>
    <div class="label">Sahara Club Spa</div>
    <div class="divider"></div>
    <h1>Pago cancelado</h1>
    <p>No se realiz&oacute; ning&uacute;n cargo.<br>
    Regresa a la app para intentarlo de nuevo.</p>
  </div>
</body>
</html>`;

Deno.serve((req: Request) => {
  const url = new URL(req.url);
  const isCancel = url.pathname.endsWith('/cancel');

  return new Response(isCancel ? cancelHtml : successHtml, {
    status: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-cache, no-store',
    },
  });
});
