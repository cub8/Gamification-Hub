import { type Page } from "@playwright/test"
import { choose, expect, type Record, test } from "@e2e/support/on-rails"

let group: Record

const templateRegion = (page: Page, name: string) => page.getByRole("region", { name, exact: true })
const sheetRow = (page: Page, name: string) => page.getByRole("main").getByRole("listitem").filter({ hasText: name })
const cell = (page: Page, student: string, category: string) => page.getByRole("cell", { name: new RegExp(`^${student}, ${category}: `) })

async function createSheet(page: Page, template = "Zajęcia") {
  await templateRegion(page, template).getByRole("link", { name: "Utwórz arkusz" }).click()
  await page.getByRole("dialog").getByRole("button", { name: "Utwórz arkusz" }).click()
}

test.beforeEach(async({ page, rails, signIn }) => {
  const scenario = await rails.scenario("group")
  group = scenario.group
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${group.id}/activity_groups`)
})

test.describe("templates", () => {
  test("creates a template with ordered categories", async({ page }) => {
    await page.getByRole("link", { name: "Nowy szablon" }).click()
    await page.getByLabel("Nazwa szablonu").fill("Laboratoria")
    await page.getByLabel("Kategoria 1: za co").fill("Obecność")
    await page.getByLabel("Nagroda za kategorię 1").fill("1")
    await page.getByLabel("Kategoria 2: za co").fill("Sprawozdanie")
    await page.getByLabel("Nagroda za kategorię 2").fill("3")
    await page.getByRole("button", { name: "Dodaj kategorię" }).click()
    await page.getByLabel("Kategoria 3: za co").fill("Aktywność")
    await page.getByLabel("Nagroda za kategorię 3").fill("2")
    // Move "Aktywność" in front of "Sprawozdanie".
    await page.getByRole("listitem").filter({ has: page.getByLabel("Kategoria 3: za co") })
      .getByRole("button", { name: "Przesuń wyżej" })
      .click()

    const header = page.getByRole("complementary", { name: "Podgląd" }).getByRole("columnheader")
    await expect(header).toHaveText([/Student/, /Obecność\s*\+1/, /Aktywność\s*\+2/, /Sprawozdanie\s*\+3/])
    await expect(page.getByText("3 kolumny w tabeli ocen. Student może zdobyć do 6")).toBeVisible()
    await page.getByRole("button", { name: "Utwórz szablon" }).click()

    await expect(page.getByText("Utworzono szablon „Laboratoria”.")).toBeVisible()
    await expect(templateRegion(page, "Laboratoria")).toContainText("Szablon: 3 kategorie, do 6 Złote monety")

    await createSheet(page, "Laboratoria")
    await sheetRow(page, "Laboratoria 1").getByRole("link", { name: "Oceń" }).click()
    await expect(page.getByRole("columnheader")).toHaveText([/Student/, /Obecność\s*\+1/, /Aktywność\s*\+2/,
      /Sprawozdanie\s*\+3/, /Razem/])
  })

  test("removes a category before saving", async({ page }) => {
    await page.getByRole("link", { name: "Nowy szablon" }).click()
    await page.getByLabel("Nazwa szablonu").fill("Wykłady")
    await page.getByLabel("Kategoria 2: za co").fill("Do usunięcia")
    await choose(page.getByRole("checkbox", { name: "Usuń kategorię 2" }))
    await page.getByRole("button", { name: "Utwórz szablon" }).click()

    await expect(templateRegion(page, "Wykłady")).toContainText("Szablon: 1 kategoria")
  })

  test("does not create a template without a name", async({ page }) => {
    await page.getByRole("link", { name: "Nowy szablon" }).click()
    await page.getByLabel("Nazwa szablonu").fill("")
    await page.getByRole("button", { name: "Utwórz szablon" }).click()

    await expect(page.getByRole("alert").first()).toBeVisible()
    await expect(page.getByRole("heading", { name: "Nowy szablon arkusza" })).toBeVisible()
  })

  test("edits a template", async({ page }) => {
    await templateRegion(page, "Zajęcia").getByRole("link", { name: "Edytuj szablon" }).click()
    await page.getByLabel("Nazwa szablonu").fill("Ćwiczenia")
    await page.getByLabel("Nagroda za kategorię 1").fill("5")
    await page.getByRole("button", { name: "Zapisz zmiany" }).click()

    await expect(page.getByText("Zapisano szablon. Nowe arkusze dostaną te kategorie.")).toBeVisible()
    await expect(templateRegion(page, "Ćwiczenia")).toContainText("do 15 Złote monety")
  })

  test("deletes a template but keeps its sheets", async({ page }) => {
    await createSheet(page)
    await expect(sheetRow(page, "Zajęcia 1")).toBeVisible()

    await templateRegion(page, "Zajęcia").getByRole("link", { name: "Edytuj szablon" }).click()
    await page.getByRole("link", { name: "Usuń szablon" }).click()
    const dialog = page.getByRole("dialog")
    await expect(dialog.getByRole("heading", { name: "Usunąć szablon „Zajęcia”?" })).toBeVisible()
    await dialog.getByRole("button", { name: "Usuń szablon" }).click()

    await expect(page.getByText("Usunięto szablon „Zajęcia”. Utworzone z niego arkusze zostają.")).toBeVisible()
    const deleted = templateRegion(page, "Zajęcia")
    await expect(deleted).toContainText("Szablon usunięty.")
    await expect(deleted.getByRole("link", { name: "Utwórz arkusz" })).toHaveCount(0)
    await expect(deleted.getByRole("link", { name: "Edytuj szablon" })).toHaveCount(0)

    await sheetRow(page, "Zajęcia 1").getByRole("link", { name: "Oceń" }).click()
    await expect(page.getByRole("heading", { name: "Zajęcia 1", level: 1 })).toBeVisible()
  })

  test("imports a template from CSV", async({ page }) => {
    await page.getByRole("link", { name: "Importuj z CSV" }).click()
    const dialog = page.getByRole("dialog")
    await dialog.locator("input[type=file]").setInputFiles("e2e/fixtures/templates.csv")
    await dialog.getByRole("button", { name: "Importuj" }).click()

    await expect(dialog.getByText("Zadanie domowe")).toBeVisible()
    await dialog.getByRole("button", { name: "Zatwierdź import" }).click()

    await expect(templateRegion(page, "Laboratorium")).toContainText("Szablon: 3 kategorie, do 6 Złote monety")
  })
})

test.describe("sheets", () => {
  test("creates a sheet named after its template", async({ page }) => {
    await templateRegion(page, "Zajęcia").getByRole("link", { name: "Utwórz arkusz" }).click()
    const dialog = page.getByRole("dialog")
    await expect(dialog.getByRole("heading", { name: "Nowy arkusz z szablonu Zajęcia" })).toBeVisible()
    await expect(dialog.getByLabel("Nazwa")).toHaveValue("Zajęcia 1")
    await dialog.getByLabel("Nazwa").fill("Zajęcia 1 (14.10)")
    await dialog.getByRole("button", { name: "Utwórz arkusz" }).click()

    await expect(page.getByText("Utworzono: Zajęcia 1 (14.10).")).toBeVisible()
    await expect(sheetRow(page, "Zajęcia 1 (14.10)")).toContainText("Jeszcze nic nie przyznano")

    // The next one continues the numbering.
    await templateRegion(page, "Zajęcia").getByRole("link", { name: "Utwórz arkusz" }).click()
    await expect(page.getByRole("dialog").getByLabel("Nazwa")).toHaveValue("Zajęcia 2")
  })

  test("creates several sheets at once", async({ page }) => {
    await templateRegion(page, "Zajęcia").getByRole("link", { name: "Utwórz arkusz" }).click()
    const dialog = page.getByRole("dialog")
    await choose(dialog.getByRole("radio", { name: "Kilka naraz" }))
    await dialog.getByRole("button", { name: /Utwórz/ }).click()

    await expect(page.getByText(/Utworzono: Zajęcia 1 – Zajęcia \d+\./)).toBeVisible()
    await expect(sheetRow(page, "Zajęcia 1")).toBeVisible()
    await expect(sheetRow(page, "Zajęcia 2")).toBeVisible()
  })

  test("renames a sheet in its settings", async({ page }) => {
    await createSheet(page)
    await sheetRow(page, "Zajęcia 1").getByRole("link", { name: "Ustawienia: Zajęcia 1" }).click()
    await page.getByLabel("Nazwa arkusza").fill("Kolokwium")
    await page.getByRole("button", { name: "Zapisz zmiany" }).click()

    await expect(page.getByText("Zapisano ustawienia arkusza Kolokwium.")).toBeVisible()
    await expect(sheetRow(page, "Kolokwium")).toBeVisible()
  })

  test("deletes a sheet", async({ page }) => {
    await createSheet(page)
    await sheetRow(page, "Zajęcia 1").getByRole("link", { name: "Ustawienia: Zajęcia 1" }).click()
    await page.getByRole("link", { name: "Usuń arkusz" }).click()
    await page.getByRole("dialog").getByRole("button", { name: "Usuń arkusz" }).click()

    await expect(page.getByText("Usunięto arkusz Zajęcia 1.")).toBeVisible()
    await expect(sheetRow(page, "Zajęcia 1")).toHaveCount(0)
  })
})

test.describe("grading", () => {
  test.beforeEach(async({ page }) => {
    await createSheet(page)
    await sheetRow(page, "Zajęcia 1").getByRole("link", { name: "Oceń" }).click()
    await expect(page.getByRole("heading", { name: "Zajęcia 1", level: 1 })).toBeVisible()
  })

  test("awards the checked categories after a review", async({ page }) => {
    await cell(page, "Jan Nowak", "Obecność").getByRole("checkbox").click({ force: true })
    await page.getByRole("columnheader", { name: /^Pomoc innym/ }).getByRole("button", { name: "Wszyscy" }).click()
    await expect(page.getByText("Zaznaczone teraz: 4 pola u 3 studentów, razem +7")).toBeVisible()

    await page.getByRole("button", { name: "Przejrzyj i przyznaj" }).click()
    const dialog = page.getByRole("dialog", { name: "Przyznajesz 7 Złote monety 3 studentom" })
    await expect(dialog.getByRole("alert")).toContainText("Po zatwierdzeniu nie da się tego cofnąć.")
    await expect(dialog.getByRole("list")).toMatchAriaSnapshot(`
      - listitem: /Jan Nowak Obecność \\+1 Pomoc innym \\+2 \\+3/
      - listitem: /Ola Zielińska Pomoc innym \\+2 \\+2/
      - listitem: /Piotr Wiśniewski Pomoc innym \\+2 \\+2/
    `)

    await dialog.getByRole("button", { name: "Przyznaj 7 Złote monety" }).click()

    await expect(page.getByText("Przyznano 7 Złote monety 3 studentom.")).toBeVisible()
    await expect(cell(page, "Jan Nowak", "Obecność").getByRole("img", { name: "Jan Nowak, Obecność: przyznane" }))
      .toBeVisible()
    await expect(page.getByRole("row").filter({ hasText: "Jan Nowak" }).getByRole("cell")
      .last()).toHaveAccessibleName("3")
    await expect(page.getByRole("button", { name: "Przejrzyj i przyznaj" })).toBeDisabled()

    await page.getByRole("link", { name: "Wróć do arkuszy" }).click()
    await expect(sheetRow(page, "Zajęcia 1")).not.toContainText("Jeszcze nic nie przyznano")
  })

  test("going back from the review keeps the selection", async({ page }) => {
    await cell(page, "Ola Zielińska", "Punktualność").getByRole("checkbox").click({ force: true })
    await page.getByRole("button", { name: "Przejrzyj i przyznaj" }).click()
    await page.getByRole("dialog").getByRole("button", { name: "Wróć do edycji" }).click()

    await expect(page.getByRole("dialog")).toBeHidden()
    await expect(cell(page, "Ola Zielińska", "Punktualność").getByRole("checkbox")).toBeChecked()
  })

  test("clears the selection", async({ page }) => {
    await page.getByRole("columnheader", { name: /^Obecność/ }).getByRole("button", { name: "Wszyscy" }).click()
    await page.getByRole("button", { name: "Wyczyść zaznaczenia" }).click()

    await expect(page.getByText("Nic nie jest zaznaczone.")).toBeVisible()
    await expect(page.getByRole("button", { name: "Przejrzyj i przyznaj" })).toBeDisabled()
  })

  test("filters students by name", async({ page }) => {
    await page.getByRole("searchbox", { name: "Szukaj studenta" }).fill("Ola")
    await expect(page.getByRole("rowheader", { name: "Ola Zielińska" })).toBeVisible()
    await expect(page.getByRole("rowheader", { name: "Jan Nowak" })).toBeHidden()
  })
})
