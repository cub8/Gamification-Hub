/**
 * Entry point for the "Card Table" redesign layout.
 *
 * Deliberately separate from application.ts: this bundle loads NO Bootstrap
 * and none of the legacy Stimulus controllers. Views on `layout "redesign"`
 * get this file; everything else keeps application.ts.
 *
 * esbuild picks this up automatically (it globs app/javascript/*.*) and emits
 * app/assets/builds/redesign.js.
 */

import "@redesign/turbo_setup"
import "@redesign/index"
