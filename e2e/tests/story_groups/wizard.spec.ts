import { type Page } from "@playwright/test"
import { choose, expect, test } from "@e2e/support/on-rails"

const next = (page: Page) => page.getByRole("button", { name: "Dalej" }).click()

async function fillBasics(page: Page, { name = "Zakon Algorytmów", currency = "Marchewek" } = {}) {
  await page.goto("/story_groups/new")
  await page.getByLabel("Nazwa grupy").fill(name)
  await page.getByLabel("Opowieść (opcjonalnie)").fill("Dawno, dawno temu w laboratorium…")
  await choose(page.getByRole("radio", { name: "Grafika grupy: Zamek" }))
  await next(page)

  await page.getByLabel("Nazwa waluty").fill(currency)
  await choose(page.getByRole("radio", { name: "Ikona waluty: Moneta" }))
}

// The visible file field of the wizard, not the hidden copies that feed the preview forms.
const csvInput = (page: Page, resource: string) => page.locator(`input[type=file][name="setup[csv][${resource}]"][data-resource]`)

async function choosePath(page: Page, path: "Szybki start" | "Od zera" | "Z plików CSV") {
  await choose(page.getByRole("radio", { name: new RegExp(path) }))
}

test.describe("creating a group", () => {
  test.beforeEach(async({ rails, signIn }) => {
    await signIn(await rails.create("user", "teacher"))
  })

  test("from scratch", async({ page }) => {
    await fillBasics(page)
    await page.getByRole("button", { name: "Więcej żyć" }).click()
    await page.getByRole("switch", { name: "Pokazuj ranking studentom" }).check()
    await page.getByLabel("Co widzą studenci").selectOption({ label: "Pełny ranking" })
    await next(page)

    await choosePath(page, "Od zera")
    await next(page)

    await expect(page.locator(".gh-summary-list dd")).toHaveText(["Zakon Algorytmów", "Marchewek", "4", "Pełny ranking"])
    await page.getByRole("button", { name: "Utwórz pustą grupę" }).click()

    await expect(page.getByRole("heading", { name: "Grupa „Zakon Algorytmów” jest gotowa" })).toBeVisible()
    await expect(page.getByText("Grupa jest pusta.")).toBeVisible()
    await page.getByRole("link", { name: "Przejdź do grupy" }).click()
    await expect(page.getByRole("heading", { name: "Zakon Algorytmów", level: 1 })).toBeVisible()
    await expect(page.getByText("Dawno, dawno temu w laboratorium…")).toBeVisible()
    await expect(page.getByRole("region", { name: "Podsumowanie grupy" })).toContainText("Pełny ranking")
  })

  test("with quick start", async({ page }) => {
    await fillBasics(page)
    await next(page)

    await choosePath(page, "Szybki start")
    await choose(page.getByRole("radio", { name: /Fantasy/ }))
    await page.getByRole("button", { name: "Mniej zajęć" }).click()
    await next(page)

    await expect(page.getByRole("heading", { name: "Zestaw „Fantasy” dla 11 zajęć" })).toBeVisible()
    await choose(page.getByRole("checkbox", { name: "Usuń: Król" }), false)
    await expect(page.getByRole("checkbox", { name: "Przywróć: Król" })).not.toBeChecked()
    await page.getByLabel("Rycerz: próg").fill("25")
    await page.getByRole("button", { name: "Utwórz grupę z zestawem" }).click()

    await expect(page.getByRole("heading", { name: "Grupa „Zakon Algorytmów” jest gotowa" })).toBeVisible()
    await expect(page.getByText("Utworzono 4 rangi, 6 odznak, 7 przedmiotów oraz 8 kategorii")).toBeVisible()

    await page.getByRole("link", { name: "Przejdź do grupy" }).click()
    await page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link", { name: "Rangi" }).click()
    const rank = (name: string) => page.locator("li.gh-rank-row").filter({ has: page.getByText(name, { exact: true }) })
    await expect(rank("Giermek")).toContainText("Ranga startowa")
    await expect(rank("Rycerz")).toContainText("Od 25 zebranych")
    await expect(rank("Król")).toHaveCount(0)
  })

  test("from CSV files, with a preview of each file", async({ page }) => {
    await fillBasics(page, { name: "Rycerze Okrągłego Stołu", currency: "Dukatów" })
    await next(page)
    await choosePath(page, "Z plików CSV")

    const previews: [string, string, string[]][] = [
      ["ranks", "Podgląd importu rang", ["Giermek", "Rycerz", "Paladyn"]],
      ["badges", "Podgląd importu odznak", ["Smokobójca", "Kronikarz"]],
      ["items", "Podgląd importu przedmiotów", ["Mikstura czasu", "Eliksir życia"]],
      ["templates", "Podgląd importu szablonów", ["Obecność", "Zadanie domowe", "Aktywność"]],
    ]
    for (const [resource, title, rows] of previews) {
      await csvInput(page, resource).setInputFiles(`e2e/fixtures/${resource}.csv`)
      const dialog = page.getByRole("dialog")
      await expect(dialog.getByRole("heading", { name: title })).toBeVisible()
      for (const row of rows) await expect(dialog.getByText(row).first()).toBeVisible()
      await dialog.getByRole("button", { name: "Zatwierdź" }).click()
      await expect(dialog).toBeHidden()
    }

    await next(page)
    await page.getByRole("button", { name: "Utwórz grupę z importu" }).click()

    await expect(page.getByRole("heading", { name: "Grupa „Rycerze Okrągłego Stołu” jest gotowa" })).toBeVisible()
    await expect(page.getByText("Utworzono 3 rangi, 2 odznaki, 2 przedmioty oraz 3 kategorie")).toBeVisible()
  })

  test("from CSV files rejects a broken file", async({ page }) => {
    await fillBasics(page)
    await next(page)
    await choosePath(page, "Z plików CSV")

    await csvInput(page, "ranks").setInputFiles("e2e/fixtures/malformed.csv")
    const dialog = page.getByRole("dialog")
    await expect(dialog.getByText("Nie udało się odczytać pliku - sprawdź, czy to poprawny plik CSV.")).toBeVisible()
    await dialog.getByRole("button", { name: "OK" }).click()

    // OK drops the broken file, so the group is created without anything imported.
    await next(page)
    await page.getByRole("button", { name: "Utwórz grupę z importu" }).click()
    await expect(page.getByText("Grupa jest pusta.")).toBeVisible()
  })

  test("does not move on without a name or a currency", async({ page }) => {
    await page.goto("/story_groups/new")
    await next(page)
    await expect(page.getByText("Podaj nazwę grupy.")).toBeVisible()
    await expect(page.getByText("Krok 1 z 4")).toBeVisible()

    await page.getByLabel("Nazwa grupy").fill("Bez waluty")
    await next(page)
    await next(page)
    await expect(page.getByText("Podaj nazwę waluty.")).toBeVisible()
    await expect(page.getByText("Krok 2 z 4")).toBeVisible()

    await page.getByLabel("Nazwa waluty").fill("Monet")
    await next(page)
    await next(page)
    await expect(page.getByText("Wybierz, jak chcesz zacząć.")).toBeVisible()
  })

  test("can go back to an earlier step", async({ page }) => {
    await fillBasics(page)
    await next(page)
    await page.getByRole("button", { name: "Wstecz" }).click()
    await expect(page.getByLabel("Nazwa waluty")).toHaveValue("Marchewek")
    await page.getByRole("button", { name: "Wstecz" }).click()
    await expect(page.getByLabel("Nazwa grupy")).toHaveValue("Zakon Algorytmów")
  })

  test("cancel returns to the group list", async({ page }) => {
    await page.goto("/story_groups/new")
    await page.getByRole("link", { name: "Anuluj" }).click()
    await expect(page).toHaveURL("/story_groups")
  })
})
