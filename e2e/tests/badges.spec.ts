import { type Page } from "@playwright/test"
import { choose, expect, type Record, test } from "@e2e/support/on-rails"

let group: Record

const badgeCard = (page: Page, name: string) => page.getByRole("main").getByRole("article").filter({ has: page.getByRole("heading", { name, exact: true }) })

test.beforeEach(async({ page, rails, signIn }) => {
  const scenario = await rails.scenario("group")
  group = scenario.group
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${group.id}/badges`)
})

test("lists the badges with their discount and how to earn them", async({ page }) => {
  await expect(page.getByText("6 odznak.")).toBeVisible()
  await expect(badgeCard(page, "Bez skazy")).toContainText("−2% w sklepie")
  await expect(badgeCard(page, "Bez skazy")).toContainText("Pierwsza wejściówka bez błędów")
  await expect(badgeCard(page, "Bez skazy")).toContainText("Nikt jej jeszcze nie ma")
})

test("adds a badge, previewing both sides of the card", async({ page }) => {
  await page.getByRole("link", { name: "Nowa odznaka" }).click()
  await page.getByLabel("Nazwa").fill("Perfekcyjny Lot")
  await page.getByLabel("Jak zdobyć").fill("Trzy wejściówki z rzędu bez błędów")
  await page.getByLabel("Opis fabularny (opcjonalnie)").fill("Lot bez najmniejszej rysy")
  await choose(page.getByRole("radio", { name: "Grafika: Rakieta" }))
  await page.getByLabel("Zniżka w sklepie").fill("4")

  const preview = page.getByRole("complementary", { name: "Podgląd" })
  await expect(preview.getByRole("heading", { name: "Perfekcyjny Lot" }).first()).toBeVisible()
  await preview.getByRole("button", { name: "Jeszcze niezdobyta" }).click()
  await expect(preview.getByRole("button", { name: "Jeszcze niezdobyta" })).toHaveAttribute("aria-pressed", "true")
  await expect(preview.getByText("Trzy wejściówki z rzędu bez błędów").first()).toBeVisible()

  await page.getByRole("button", { name: "Dodaj odznakę" }).click()

  await expect(page.getByText("Dodano odznakę „Perfekcyjny Lot”.")).toBeVisible()
  await expect(badgeCard(page, "Perfekcyjny Lot")).toContainText("−4% w sklepie")
  await expect(badgeCard(page, "Perfekcyjny Lot")).toContainText("Trzy wejściówki z rzędu bez błędów")
  await expect(page.getByText("7 odznak.")).toBeVisible()
})

test("does not add a badge without a name", async({ page }) => {
  await page.getByRole("link", { name: "Nowa odznaka" }).click()
  await page.getByLabel("Jak zdobyć").fill("Cokolwiek")
  await page.getByRole("button", { name: "Dodaj odznakę" }).click()

  await expect(page.getByRole("alert").first()).toBeVisible()
  await expect(page.getByRole("heading", { name: "Nowa odznaka" })).toBeVisible()
})

test("edits a badge", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj odznakę Bez skazy" }).click()
  await expect(page.getByRole("heading", { name: "Edytuj odznakę" })).toBeVisible()
  await page.getByLabel("Nazwa").fill("Czysta karta")
  await page.getByLabel("Zniżka w sklepie").fill("6")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByText("Zapisano odznakę „Czysta karta”.")).toBeVisible()
  await expect(badgeCard(page, "Czysta karta")).toContainText("−6% w sklepie")
  await expect(badgeCard(page, "Bez skazy")).toHaveCount(0)
})

test("deletes a badge", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj odznakę Głos grupy" }).click()
  await page.getByRole("link", { name: "Usuń odznakę" }).click()

  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Usunąć odznakę „Głos grupy”?" })).toBeVisible()
  await dialog.getByRole("button", { name: "Usuń odznakę" }).click()

  await expect(page.getByText("Usunięto odznakę „Głos grupy”.")).toBeVisible()
  await expect(badgeCard(page, "Głos grupy")).toHaveCount(0)
  await expect(page.getByText("5 odznak.")).toBeVisible()
})

test("imports badges from CSV after a preview", async({ page }) => {
  await page.getByRole("link", { name: "Importuj z CSV" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.locator("input[type=file]").setInputFiles("e2e/fixtures/badges.csv")
  await dialog.getByRole("button", { name: "Importuj" }).click()

  await expect(dialog.getByText("Smokobójca")).toBeVisible()
  await dialog.getByRole("button", { name: "Zatwierdź import" }).click()

  await expect(badgeCard(page, "Smokobójca")).toContainText("Rozwiązanie zadania z gwiazdką")
  await expect(badgeCard(page, "Kronikarz")).toContainText("−3% w sklepie")
  await expect(page.getByText("8 odznak.")).toBeVisible()
})
