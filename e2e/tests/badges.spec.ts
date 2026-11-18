import { card, choose, expect, importCsv, test } from "@e2e/support/on-rails"

test.beforeEach(async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/badges`)
})

test("lists the badges with their discount and how to earn them", async({ page }) => {
  await expect(page.getByText("6 odznak.")).toBeVisible()
  await expect(card(page, "Bez skazy")).toContainText(/−2% w sklepie.*Pierwsza wejściówka bez błędów.*Nikt jej/s)
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
  await expect(card(page, "Perfekcyjny Lot")).toContainText(/−4% w sklepie.*Trzy wejściówki z rzędu bez błędów/s)
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
  await page.getByLabel("Nazwa").fill("Czysta karta")
  await page.getByLabel("Zniżka w sklepie").fill("6")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByText("Zapisano odznakę „Czysta karta”.")).toBeVisible()
  await expect(card(page, "Czysta karta")).toContainText("−6% w sklepie")
  await expect(card(page, "Bez skazy")).toHaveCount(0)
})

test("deletes a badge", async({ page }) => {
  await page.getByRole("link", { name: "Edytuj odznakę Głos grupy" }).click()
  await page.getByRole("link", { name: "Usuń odznakę" }).click()

  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Usunąć odznakę „Głos grupy”?" })).toBeVisible()
  await dialog.getByRole("button", { name: "Usuń odznakę" }).click()

  await expect(page.getByText("Usunięto odznakę „Głos grupy”.")).toBeVisible()
  await expect(card(page, "Głos grupy")).toHaveCount(0)
  await expect(page.getByText("5 odznak.")).toBeVisible()
})

test("imports badges from CSV after a preview", async({ page }) => {
  const dialog = await importCsv(page, "badges.csv")
  await expect(dialog.getByText("Smokobójca")).toBeVisible()
  await dialog.getByRole("button", { name: "Zatwierdź import" }).click()

  await expect(card(page, "Smokobójca")).toContainText("Rozwiązanie zadania z gwiazdką")
  await expect(card(page, "Kronikarz")).toContainText("−3% w sklepie")
  await expect(page.getByText("8 odznak.")).toBeVisible()
})
