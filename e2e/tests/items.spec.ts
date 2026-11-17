import { type Page } from "@playwright/test"
import { choose, expect, type Record, test } from "@e2e/support/on-rails"

let group: Record

const itemCard = (page: Page, name: string) => page.getByRole("main").getByRole("article").filter({ has: page.getByRole("heading", { name, exact: true }) })

test.beforeEach(async({ page, rails, signIn }) => {
  const scenario = await rails.scenario("group")
  group = scenario.group
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${group.id}/items`)
})

test("lists the shop items from the cheapest, with their requirements", async({ page }) => {
  await expect(page.getByText("7 przedmiotów w sklepie, od najtańszego.")).toBeVisible()
  const names = await page.getByRole("main").getByRole("article").getByRole("heading")
    .allTextContents()
  expect(names[0]).toBe("+5 minut do wejściówki")
  expect(names.at(-1)).toBe("+0.5 oceny końcowej")
  await expect(itemCard(page, "Poprawa wejściówki")).toContainText("Od rangi Uczeń")
  await expect(itemCard(page, "1up: odzyskanie życia")).toContainText("Przy 0 życiach")
})

test("adds an item with a rank and a badge requirement", async({ page }) => {
  await page.getByRole("link", { name: "Nowy przedmiot" }).click()
  await page.getByLabel("Nazwa").fill("Kryształ mocy")
  await page.getByLabel("Co daje studentowi").fill("Jedno dodatkowe pytanie na kolokwium")
  await page.getByLabel("Opis fabularny (opcjonalnie)").fill("Lśni w ciemności")
  await choose(page.getByRole("radio", { name: "Grafika: Kolba" }))
  await page.getByLabel("Cena", { exact: true }).fill("40")
  await choose(page.getByRole("checkbox", { name: "Można kupić przy 0 życiach" }))
  await page.getByLabel("Kto może kupić").selectOption({ label: "od rangi Adept" })
  await page.getByRole("combobox", { name: "Wymagane odznaki" }).selectOption({ label: "Bez skazy" })
  await page.getByLabel("Zniżka dla rang").selectOption({ label: "od Ekspert (−10% i więcej)" })
  await page.getByRole("combobox", { name: "Odznaki ze zniżką" }).selectOption({ label: "Głos grupy (−7%)" })

  const preview = page.getByRole("complementary", { name: "Podgląd" })
  await expect(preview.getByRole("heading", { name: "Kryształ mocy" })).toBeVisible()
  await expect(preview.getByRole("button", { name: "Kup za 40" })).toBeVisible()

  await page.getByRole("button", { name: "Dodaj przedmiot" }).click()

  await expect(page.getByText("Dodano przedmiot „Kryształ mocy” do sklepu.")).toBeVisible()
  const card = itemCard(page, "Kryształ mocy")
  await expect(card).toContainText("40")
  await expect(card).toContainText("Od rangi Adept")
  await expect(card).toContainText("Przy 0 życiach")
  await expect(page.getByText("8 przedmiotów w sklepie")).toBeVisible()

  await card.getByRole("link", { name: "Edytuj przedmiot Kryształ mocy" }).click()
  await expect(page.getByLabel("Kto może kupić")).toHaveValue(/.+/)
  await expect(page.getByRole("checkbox", { name: "Można kupić przy 0 życiach" })).toBeChecked()
  await expect(page.getByRole("group", { name: "Wymagane odznaki" })).toContainText("Bez skazy")
  await expect(page.getByRole("group", { name: "Odznaki ze zniżką" })).toContainText("Głos grupy")
})

test("does not add an item without a name", async({ page }) => {
  await page.getByRole("link", { name: "Nowy przedmiot" }).click()
  await page.getByLabel("Co daje studentowi").fill("Coś")
  await page.getByRole("button", { name: "Dodaj przedmiot" }).click()

  await expect(page.getByRole("alert").first()).toBeVisible()
  await expect(page.getByRole("heading", { name: "Nowy przedmiot" })).toBeVisible()
})

test("edits an item's price", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj przedmiot Konsultacja" }).click()
  await expect(page.getByRole("heading", { name: "Edytuj przedmiot" })).toBeVisible()
  await page.getByLabel("Cena", { exact: true }).fill("99")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByText("Zapisano „Konsultacja”. Zmiany dotyczą nowych zakupów.")).toBeVisible()
  await expect(itemCard(page, "Konsultacja")).toContainText("99")
  // Sorted by price, so it is now the most expensive one.
  const names = await page.getByRole("main").getByRole("article").getByRole("heading")
    .allTextContents()
  expect(names.at(-1)).toBe("Konsultacja")
})

test("removes an item from the shop", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj przedmiot Konsultacja" }).click()
  await page.getByRole("link", { name: "Usuń przedmiot" }).click()

  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Usunąć „Konsultacja” ze sklepu?" })).toBeVisible()
  await dialog.getByRole("button", { name: "Usuń z oferty" }).click()

  await expect(page.getByText("Usunięto „Konsultacja” z oferty.")).toBeVisible()
  await expect(itemCard(page, "Konsultacja")).toHaveCount(0)
  await expect(page.getByText("6 przedmiotów w sklepie")).toBeVisible()
})

test("imports items from CSV, linked to the group's ranks and badges", async({ page }) => {
  await page.getByRole("link", { name: "Importuj z CSV" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.locator("input[type=file]").first().setInputFiles("e2e/fixtures/items_more.csv")
  await dialog.getByRole("button", { name: "Importuj" }).click()

  await expect(dialog.getByText("Kryształ mocy")).toBeVisible()
  await dialog.getByRole("button", { name: "Zatwierdź import" }).click()

  await expect(itemCard(page, "Kryształ mocy")).toContainText("Od rangi Adept")
  await expect(page.getByText("8 przedmiotów w sklepie")).toBeVisible()
})
