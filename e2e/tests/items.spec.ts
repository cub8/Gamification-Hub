import { type Page } from "@playwright/test"
import { card, choose, expect, importCsv, test } from "@e2e/support/on-rails"

const itemNames = (page: Page) => page.getByRole("main").getByRole("article").getByRole("heading")
  .allTextContents()

test.beforeEach(async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/items`)
})

test("lists the shop items from the cheapest, with their requirements", async({ page }) => {
  await expect(page.getByText("7 przedmiotów w sklepie, od najtańszego.")).toBeVisible()
  const names = await itemNames(page)
  expect(names[0]).toBe("+5 minut do wejściówki")
  expect(names.at(-1)).toBe("+0.5 oceny końcowej")
  await expect(card(page, "Poprawa wejściówki")).toContainText("Od rangi Uczeń")
  await expect(card(page, "1up: odzyskanie życia")).toContainText("Przy 0 życiach")
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
  await expect(card(page, "Kryształ mocy")).toContainText(/40.*Od rangi Adept.*Przy 0 życiach/s)
  await expect(page.getByText("8 przedmiotów w sklepie")).toBeVisible()

  await page.getByRole("link", { name: "Edytuj przedmiot Kryształ mocy" }).click()
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

test("edits an item's price, which moves it in the price order", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj przedmiot Konsultacja" }).click()
  await page.getByLabel("Cena", { exact: true }).fill("99")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByText("Zapisano „Konsultacja”. Zmiany dotyczą nowych zakupów.")).toBeVisible()
  await expect(card(page, "Konsultacja")).toContainText("99")
  expect((await itemNames(page)).at(-1)).toBe("Konsultacja")
})

test("removes an item from the shop", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj przedmiot Konsultacja" }).click()
  await page.getByRole("link", { name: "Usuń przedmiot" }).click()

  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Usunąć „Konsultacja” ze sklepu?" })).toBeVisible()
  await dialog.getByRole("button", { name: "Usuń z oferty" }).click()

  await expect(page.getByText("Usunięto „Konsultacja” z oferty.")).toBeVisible()
  await expect(card(page, "Konsultacja")).toHaveCount(0)
  await expect(page.getByText("6 przedmiotów w sklepie")).toBeVisible()
})

test("imports items from CSV, linked to the group's ranks and badges", async({ page }) => {
  const dialog = await importCsv(page, "items_more.csv")
  await expect(dialog.getByText("Kryształ mocy")).toBeVisible()
  await dialog.getByRole("button", { name: "Zatwierdź import" }).click()

  await expect(card(page, "Kryształ mocy")).toContainText("Od rangi Adept")
  await expect(page.getByText("8 przedmiotów w sklepie")).toBeVisible()
})
