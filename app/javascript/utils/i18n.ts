// Client-side halves of Rails I18n. The wording itself always comes from the
// view (config/locales/**), passed in as a Stimulus value; these only fill it in.

// A pluralised key as Rails returns it when called without `count:` —
// pl has one/few/many/other, en has one/other.
export type PluralForms = Partial<Record<Intl.LDMLPluralRule, string>>

type Vars = Record<string, string | number>

// The page's language, set on <html lang> by the Localization concern.
export function locale(): string {
  return document.documentElement.lang || "pl"
}

// "%{name} ma %{count}" + { name: "Ala", count: 3 } -> "Ala ma 3".
export function interpolate(template: string, vars: Vars = {}): string {
  return template.replace(/%\{(\w+)\}/g, (match, key: string) => (key in vars ? String(vars[key]) : match))
}

// The form for `count`, unfilled — the same rule rails-i18n applies on the server.
export function pluralTemplate(forms: PluralForms, count: number): string {
  const rule = new Intl.PluralRules(locale()).select(count)

  return forms[rule] ?? forms.other ?? ""
}

export function pluralize(forms: PluralForms, count: number, vars: Vars = {}): string {
  return interpolate(pluralTemplate(forms, count), { count, ...vars })
}

// "a, b i c" / "a, b, and c" — matches Array#to_sentence with rails-i18n.
export function andList(names: string[]): string {
  return new Intl.ListFormat(locale(), { type: "conjunction" }).format(names)
}
