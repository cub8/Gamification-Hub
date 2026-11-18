import { type Page } from "@playwright/test"
import { choose, expect, importCsv, test } from "@e2e/support/on-rails"

const rankRow = (page: Page, name: string) => page.locator("li.gh-rank-row").filter({ has: page.getByText(name, { exact: true }) })

test.beforeEach(async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/ranks`)
})

test("lists the ranks from the lowest threshold up, with the students who hold them", async({ page }) => {
  await expect(page.getByText("5 rang.")).toBeVisible()
  await expect(rankRow(page, "Nowicjusz")).toContainText("Ranga startowa, bez zniżki")
  await expect(rankRow(page, "Uczeń")).toContainText("Od 20 zebranych, −3% w sklepie")
  // The scenario student has collected 50, which is Adept.
  await expect(rankRow(page, "Adept").getByRole("link", { name: "1 student" })).toBeVisible()
})

test("adds a rank", async({ page, scenario }) => {
  await page.getByRole("link", { name: "Nowa ranga" }).click()
  await page.getByLabel("Nazwa").fill("Arcymistrz")
  await choose(page.getByRole("radio", { name: "Grafika: Korona" }))
  await page.getByLabel("Wymagane zebrane").fill("150")
  await page.getByLabel("Zniżka w sklepie").fill("20")
  await expect(page.getByRole("complementary", { name: "Podgląd" }).getByText("Arcymistrz (ta ranga)")).toBeVisible()
  await page.getByRole("button", { name: "Dodaj rangę" }).click()

  await expect(page.getByText("Dodano rangę „Arcymistrz”.")).toBeVisible()
  await expect(page).toHaveURL(`/story_groups/${scenario.group.id}/ranks`)
  await expect(rankRow(page, "Arcymistrz")).toContainText("Od 150 zebranych, −20% w sklepie")
  await expect(page.getByText("6 rang.")).toBeVisible()
})

test("does not add a rank without a name", async({ page }) => {
  await page.getByRole("link", { name: "Nowa ranga" }).click()
  await page.getByLabel("Wymagane zebrane").fill("150")
  await page.getByRole("button", { name: "Dodaj rangę" }).click()

  await expect(page.getByRole("alert").first()).toBeVisible()
  await page.getByRole("link", { name: "Anuluj" }).click()
  await expect(page.getByText("5 rang.")).toBeVisible()
})

test("edits a rank, which moves students between ranks", async({ page }) => {
  await rankRow(page, "Adept").getByRole("link", { name: "Edytuj" }).click()
  await expect(page.getByRole("heading", { name: "Edytuj rangę" })).toBeVisible()
  await page.getByLabel("Nazwa").fill("Czeladnik")
  await page.getByLabel("Wymagane zebrane").fill("55")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByText("Zapisano rangę „Czeladnik”.")).toBeVisible()
  await expect(rankRow(page, "Czeladnik")).toContainText("Od 55 zebranych")
  await expect(rankRow(page, "Adept")).toHaveCount(0)
  // At 50 collected the student no longer reaches the edited rank.
  await expect(rankRow(page, "Uczeń").getByRole("link", { name: "1 student" })).toBeVisible()
})

test("cannot delete a rank that an item requires", async({ page }) => {
  await rankRow(page, "Uczeń").getByRole("link", { name: "Edytuj" }).click()
  await page.getByRole("link", { name: "Usuń rangę" }).click()

  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Usunąć rangę „Uczeń”?" })).toBeVisible()
  await expect(dialog.getByRole("alert")).toContainText("Przedmiot Poprawa wejściówki wymaga tej rangi.")
  await expect(dialog.getByRole("button", { name: "Usuń rangę" })).toBeDisabled()
})

test("deletes a rank", async({ page, rails, scenario }) => {
  await rails.create("rank", { "story_group_id": scenario.group.id, name: "Legenda", "required_currency_value": 500 })
  await page.reload()

  await rankRow(page, "Legenda").getByRole("link", { name: "Edytuj" }).click()
  await page.getByRole("link", { name: "Usuń rangę" }).click()
  await page.getByRole("dialog").getByRole("button", { name: "Usuń rangę" }).click()

  await expect(page.getByText("Usunięto rangę „Legenda”.")).toBeVisible()
  await expect(rankRow(page, "Legenda")).toHaveCount(0)
})

test("imports ranks from CSV after a preview", async({ page }) => {
  const dialog = await importCsv(page, "ranks_more.csv")
  await expect(dialog.getByText("Paladyn")).toBeVisible()
  await dialog.getByRole("button", { name: "Zatwierdź import" }).click()

  await expect(rankRow(page, "Rycerz")).toContainText("Od 30 zebranych, −5% w sklepie")
  await expect(rankRow(page, "Paladyn")).toContainText("Od 80 zebranych, −8% w sklepie")
  await expect(page.getByText("7 rang.")).toBeVisible()
})

test("rejects a CSV whose rank takes a threshold that is already used", async({ page }) => {
  const dialog = await importCsv(page, "ranks.csv")
  await expect(dialog.getByRole("alert"))
    .toHaveText("Plik zawiera nieprawidłowe dane: Ranga Nowicjusz ma już próg 0. Wybierz inny.")
  await dialog.getByRole("button", { name: "Anuluj" }).click()
  await expect(page.getByText("5 rang.")).toBeVisible()
})
