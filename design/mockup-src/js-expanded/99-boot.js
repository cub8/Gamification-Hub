/* ===== boot ===== */
buildToolbar();
const qrBtn = document.getElementById('tb-qr');
qrBtn.addEventListener('click', () => { const on = MODS.auth.qr(); qrBtn.textContent = 'Pending QR join: ' + (on ? 'on' : 'off'); });
layout();
nav(fromHash() || 'out/login');
window.mock = {G, DB, MODS, nav, render, ROUTE};
