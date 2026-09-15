/**
 * One-off: turn the mockup's inline glyph map into real .svg assets.
 *
 * The mockup keeps its preset card art as raw path data in `GL`
 * (js-expanded/00-shared.js), assembled by `fs(d)` into a filled-ghost plus a
 * stroked-outline pair. The app wants one file per glyph instead, so this
 * slices those declarations out of the source, evaluates them, and writes the
 * whole set to app/assets/images/redesign/glyphs/.
 *
 * Re-runnable: rewrites every file from the mockup, so the mockup stays the
 * single source of truth for the artwork.
 *
 *   node design/mockup-src/tools/extract_glyphs.mjs
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../..")
const source = readFileSync(`${root}/design/mockup-src/js-expanded/00-shared.js`, "utf8")

// From `const fs =` through the end of the GL object literal. Taking a slice
// rather than importing the file: 00-shared.js is browser code that touches
// `document` the moment it is loaded.
const start = source.indexOf("const fs = d =>")
const end = source.indexOf("\n};", source.indexOf("const GL = {")) + 3
if (start < 0 || end < 3) throw new Error("could not find the GL block in 00-shared.js")

const GL = new Function(`${source.slice(start, end)}\nreturn GL`)()

// The presentation the mockup puts on `.gph` (00-base.css:150-151), baked into
// the file so it still draws correctly if it is ever used outside our CSS.
// `currentColor` is the point: it is what tints a glyph gold on a rank card and
// teal on a badge, and flips it between themes.
const wrap = (paths) =>
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" ' +
  'stroke="currentColor" stroke-width="3.4" stroke-linecap="square" ' +
  `stroke-linejoin="miter">${paths}</svg>\n`

const out = `${root}/app/assets/images/redesign/glyphs`
mkdirSync(out, { recursive: true })

const keys = Object.keys(GL).sort()
for (const key of keys) writeFileSync(`${out}/${key}.svg`, wrap(GL[key]))

console.log(`${keys.length} glyphs -> app/assets/images/redesign/glyphs/`)
console.log(keys.join(" "))
