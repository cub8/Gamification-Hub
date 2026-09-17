/* ===== module: test (upload stress test, dev-only, from t/test.html) ===== */
(() => {
const html = (() => {
const IMG=__IMG_JSON__;
const VEC='<svg viewBox="0 0 24 24"><path class="f" d="M15.5 7.5L2.5 21.5l14.5-11z"/><path d="M15.5 7.5L2.5 21.5l14.5-11z"/><path d="M16 7.5l1-5.5M17 9l5.5-1.5M17.3 7.2L21.5 3"/></svg>';
const CUR=[{k:'vec',l:'Preset (vector)'},{k:'carrot',l:'golden_carrot.png<br><small>pixel art, 160px</small>',px:1},{k:'dolO',l:'dollar-outline.png'},{k:'dol',l:'dollar.png'}];
const im=c=>c.k==='vec'?VEC:`<img src="${IMG[c.k]}" alt=""${c.px?' class="px"':''}>`;
const tok=(c,s)=>`<span class="tok" style="--s:${s}px"><span>${im(c)}</span></span>`;
const bleed=(c,s)=>`<span class="bleed" style="--s:${s}px">${im(c)}</span>`;
const F=(h,cap)=>`<figure class="smp">${h}<figcaption>${cap}</figcaption></figure>`;
const rawIcon=c=>c.k==='vec'?`<svg class="cicon" viewBox="0 0 24 24">${VEC.slice(VEC.indexOf('>')+1,-6)}</svg>`:im(c);
function curRow(c){return `<div class="crow"><div class="clab">${c.l}</div>
<div class="grp">${F(`<span class="coin" style="width:32px;height:32px">${im(c)}</span>`,'coin 32px')}${F(`<span class="cost"><b>15</b>${rawIcon(c)}</span>`,'price chip 16px')}</div>
<div class="grp">${F(`<span class="bal">${tok(c,32)}<span><b>19</b><small>do wydania</small></span></span>`,'header chip 32')}${F(`<span class="purse-t">${tok(c,54)}<b>19</b></span>`,'purse 54')}${F(`<span class="dlg-t">15${tok(c,22)}</span>`,'dialog 22')}${F(`<span class="cost"><b>15</b>${tok(c,18)}</span>`,'price chip 18')}${F(`<span class="cost"><b>15</b></span>`,'number only')}</div>
<div class="grp">${c.k==='vec'?'<small class="k">n/a</small>':F(`<span class="bal">${bleed(c,32)}<span><b>19</b></span></span>`,'header 32')+F(`<span class="cost"><b>15</b>${bleed(c,18)}</span>`,'chip 18')}</div></div>`;}
const card=(o)=>`<article class="card ${o.cls}${o.sealed?' sealed':''}"><div class="card-f"><div class="card-i">
<div class="card-top"><h3 class="card-name">${o.name}</h3>${o.cost?`<span class="cost"><b>${o.cost}</b></span>`:''}</div>
<div class="art"><img src="${IMG[o.img]}" alt="" style="object-position:${o.pos||'50% 50%'}">${o.sealed?`<span class="seal"><svg class="ic" viewBox="0 0 24 24"><path d="M5 11h14v10H5z"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg><span>${o.seal}</span></span>`:''}</div>
${o.tag?`<div class="tags"><span class="tag tag-disc">${o.tag}</span></div>`:''}<p class="rules">${o.rules}</p><p class="flavor">${o.flavor}</p></div></div></article>`;
const A=[
 {cls:'item',img:'sar',name:'Wróżba z kuli',cost:25,rules:'Jedna podpowiedź od prowadzącego podczas kolokwium',flavor:'Kula widzi więcej, niż chciałbyś wiedzieć',seal:'Od rangi Strateg Imperium'},
 {cls:'badge',img:'rocky',name:'Duch drużyny',tag:'−3% w sklepie',rules:'Dopingowanie grupy przez cały semestr',flavor:'Maskotka nigdy nie opuszcza trybun',seal:'Jeszcze niezdobyta'},
 {cls:'gold',img:'civ',name:'Pilot Marcheton-7',rules:'Wymagane: 80 zebranych. Daje −5% w sklepie.',flavor:'Dowództwo powierza Ci całą flotę',seal:'Zebrane: 34 z 80'}];
const mini=k=>`<span class="card item mc"><span class="card-f"><span class="card-i"><img src="${IMG[k]}" alt=""></span></span></span>`;
const panel=t=>`<div class="app t" data-theme="${t}"><p class="ptitle">${t==='light'?'Light':'Dark'} theme</p>
<div class="crow h"><div>Upload</div><div>Current mockup rule (icon straight on gold)</div><div>Proposed: fixed gold rim + cream token</div><div>Option: “already a coin” (no frame)</div></div>${CUR.map(curRow).join('')}</div>`;
const apanel=t=>`<div class="app t" data-theme="${t}"><p class="ptitle">${t==='light'?'Light':'Dark'} theme · cards, center crop (default)</p>
<div class="acards">${A.map(o=>card(o)).join('')}${A.map(o=>card({...o,sealed:1})).join('')}</div>
<div class="arow2"><div><p class="ptitle">52px thumbnails (dashboard, notifications)</p><div class="thumbs">${['sar','rocky','civ'].map(mini).join('')}</div></div>
<div><p class="ptitle">Rocky: center crop vs. focal point set at upload</p><div class="thumbs"><div class="crop">${card({...A[1],name:'Center crop'})}</div><div class="crop">${card({...A[1],name:'Focal point: top',pos:'50% 12%'})}</div></div></div></div></div>`;
return `<h2 class="sec" id="s1">1 · Currency icon uploads</h2><p class="lede">Same placements as the mockup. Left: the current rule. Middle: proposed treatment. Right: optional “my icon is already a coin” mode.</p>${panel('light')}${panel('dark')}
<h2 class="sec" id="s2">2 · Photo uploads as item / badge / rank art</h2><p class="lede">Item (orange), badge (teal) and rank (gold) frames with the three test images, available and sealed. Sealed photos are desaturated and dimmed under the seal pattern.</p>${apanel('light')}${apanel('dark')}`;

})();
reg('test', {
  act: {},
  setView() {},
  page() { return `<main class="main" id="main"><div class="wrap" id="w">${html}</div></main>`; }
});
})();
