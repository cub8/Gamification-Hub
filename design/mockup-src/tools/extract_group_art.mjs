/**
 * One-off: turn the mockup's story-group presets into real .svg assets.
 *
 * Two sets, both kept inline in the mockup and both wanted as files here:
 *
 *   - Group art ("Grafika grupy") — 160x90 scenes, full colour. The wizard's
 *     `ART` (30-form.js) is the source rather than the settings screen's own
 *     copy (30-isg.js) or 00-shared.js's: three divergent copies exist, and the
 *     wizard's is the superset AND the only one carrying Polish labels.
 *     `rabbits` is skipped — it is a stock photograph, not generated art.
 *   - Currency icons ("Ikona waluty") — 24x24 marks, currentColor. The wizard's
 *     `CV` plus `bit`, which only the settings screen offers (30-isg.js:56).
 *
 * Sibling of extract_glyphs.mjs and re-runnable for the same reason: the mockup
 * stays the single source of truth for the artwork.
 *
 *   node design/mockup-src/tools/extract_group_art.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../..")
const read = (file) => readFileSync(`${root}/design/mockup-src/js-expanded/${file}`, "utf8")

// Slices rather than imports, exactly as extract_glyphs.mjs does it: both files
// are browser code that touches `document` the moment they are loaded.
const slice = (source, from, to, what) => {
  const start = source.indexOf(from)
  const end = source.indexOf(to, start)
  if (start < 0 || end < 0) throw new Error(`could not find ${what}`)
  return source.slice(start, end + to.length)
}

const shared = read("00-shared.js")
const form = read("30-form.js")

// `fs(d)` pairs a translucent fill layer with a stroked outline; the currency
// marks are built from it and so is `CI.bit`.
const fsDecl = slice(shared, "const fs = d =>", "\n", "the fs helper in 00-shared.js")
const bit = slice(shared, "  bit: fs(", "\n", "CI.bit in 00-shared.js").replace(/^\s*bit:\s*/, "").trim()

const CV = new Function(`${fsDecl}\n${slice(form, "const CV={", "};", "CV in 30-form.js")}\nreturn CV`)()
const CVN = new Function(`${slice(form, "const CVN={", "};", "CVN in 30-form.js")}\nreturn CVN`)()
CV.bit = new Function(`${fsDecl}\nreturn ${bit}`)()
CVN.bit = "Bit"

// `sv(b)` is the wizard's own wrapper; ART entries are {l: label, u: css url()}.
const ART = new Function(
  `${slice(form, "const svgUrl=s=>", "\n", "svgUrl in 30-form.js")}
   ${slice(form, "const sv=b=>", "\n", "sv in 30-form.js")}
   ${slice(form, "const ART={", "};", "ART in 30-form.js")}
   return ART`,
)()

// The scenes come back as `url('data:image/svg+xml,...')`, which is how CSS
// wants them and not how a file does. Unwrap back to the document.
const fromDataUrl = (css) => decodeURIComponent(css.replace(/^url\('data:image\/svg\+xml;charset=utf-8,/, "").replace(/'\)$/, ""))

// The presentation the mockup puts on `.pz.cur svg` (20-form.css:40), baked in
// so the mark still draws outside our CSS. `currentColor`, like the glyphs: one
// file has to work on the cream token face and in both themes.
const wrapMark = (paths) =>
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" ' +
  'stroke="currentColor" stroke-width="1.9" stroke-linecap="square">' +
  `${paths}</svg>\n`

const write = (dir, files) => {
  const out = `${root}/app/assets/images/${dir}`
  mkdirSync(out, { recursive: true })
  for (const [key, body] of files) writeFileSync(`${out}/${key}.svg`, body)
  console.log(`${files.length} -> app/assets/images/${dir}/`)
  console.log(files.map(([key]) => key).join(" "))
}

write(
  "redesign/art",
  Object.entries(ART)
    .filter(([key]) => key !== "rabbits")
    .map(([key, art]) => [key, `${fromDataUrl(art.u)}\n`]),
)

write(
  "redesign/currency",
  Object.entries(CV).map(([key, paths]) => [key, wrapMark(paths)]),
)

console.log("\nlabels for the registries:")
console.log("  art:", Object.entries(ART).filter(([k]) => k !== "rabbits").map(([k, a]) => `${k}=${a.l}`).join(" "))
console.log("  currency:", Object.entries(CVN).map(([k, l]) => `${k}=${l}`).join(" "))
