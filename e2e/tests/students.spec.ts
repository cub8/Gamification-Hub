import { type Page } from "@playwright/test"
import { choose, expect, type Record, test } from "@e2e/support/on-rails"

let group: Record

const studentRow = (page: Page, name: string) => page.getByRole("main").getByRole("listitem").filter({ has: page.getByRole("link", { name: new RegExp(`^${name}`) }) })

test.beforeEach(async({ page, rails, signIn }) => {
  const scenario = await rails.scenario("group")
  group = scenario.group
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${group.id}/students`)
})

test("lists students with their rank, lives and currency", async({ page }) => {
  await expect(page.getByRole("main").getByRole("listitem")).toHaveCount(3)
  const jan = studentRow(page, "Jan Nowak")
  await expect(jan).toContainText("„Kometa” · jan.nowak@example.com")
  await expect(jan).toContainText("Adept")
  await expect(studentRow(page, "Ola Zielińska")).toContainText("Nowicjusz")
})

test("searches students by name", async({ page }) => {
  await page.getByRole("searchbox", { name: "Szukaj studenta" }).fill("Zieli")
  await expect(studentRow(page, "Ola Zielińska")).toBeVisible()
  await expect(studentRow(page, "Jan Nowak")).toBeHidden()
})

test("takes and gives back a life from the list", async({ page }) => {
  await page.getByRole("button", { name: "Odbierz życie: Jan Nowak" }).click()
  await expect(page.getByText("Kometa ma teraz 2 życia.")).toBeVisible()

  await page.getByRole("button", { name: "Dodaj życie: Jan Nowak" }).click()
  await expect(page.getByText("Kometa ma teraz 3 życia.")).toBeVisible()
})

test("cannot take a life from a student who has none", async({ page }) => {
  await expect(page.getByRole("button", { name: "Odbierz życie: Piotr Wiśniewski" })).toBeDisabled()
})

test("shows a student's profile", async({ page }) => {
  await page.getByRole("link", { name: /^Jan Nowak/ }).click()
  await expect(page.getByRole("heading", { name: "Jan Nowak", level: 1 })).toBeVisible()
  await expect(page.getByText("Pseudonim: Kometa, jan.nowak@example.com")).toBeVisible()
  await expect(page.getByRole("definition").first()).toContainText("Adept 50 z 65 do rangi Ekspert")
})

test("adds and takes away currency, which shows in the history", async({ page }) => {
  await page.getByRole("link", { name: "Koryguj walutę: Jan Nowak" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByText("Kometa ma teraz 50 do wydania.")).toBeVisible()
  await dialog.getByLabel("Ile").fill("15")
  await dialog.getByRole("button", { name: /Dodaj/ }).last().click()
  await expect(page.getByText(/Dodano 15\b.*Saldo: 65\b/)).toBeVisible()

  await page.getByRole("link", { name: "Koryguj walutę: Jan Nowak" }).click()
  await choose(dialog.getByRole("radio", { name: "Odejmij" }))
  await dialog.getByLabel("Ile").fill("5")
  await dialog.getByRole("button", { name: /Odejmij/ }).last().click()
  await expect(page.getByText(/Odjęto 5\b.*Saldo: 60\b/)).toBeVisible()

  await page.getByRole("link", { name: "Historia: Jan Nowak" }).click()
  const history = page.getByRole("main")
  await expect(history).toContainText("+15")
  await expect(history).toContainText("−5")
})

test("cannot take away more currency than the student has", async({ page }) => {
  await page.getByRole("link", { name: "Koryguj walutę: Ola Zielińska" }).click()
  const dialog = page.getByRole("dialog")
  await choose(dialog.getByRole("radio", { name: "Odejmij" }))
  await dialog.getByLabel("Ile").fill("500")

  await expect(dialog.getByRole("button", { name: /Odejmij/ }).last()).toBeDisabled()
})

test("awards and revokes a badge", async({ page }) => {
  await page.getByRole("link", { name: "Przyznaj odznakę: Jan Nowak" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByText("Kometa ma 0 z 6 odznak.")).toBeVisible()
  await dialog.getByRole("searchbox", { name: "Szukaj odznaki" }).fill("Głos")
  await expect(dialog.getByRole("radio")).toHaveCount(1)
  await choose(dialog.getByRole("radio", { name: /^Głos grupy/ }))
  await dialog.getByRole("button", { name: /Przyznaj/ }).click()
  await expect(page.getByText("Przyznano odznakę „Głos grupy”.")).toBeVisible()

  // Awarding lands on the student's profile.
  await expect(page.getByRole("heading", { name: "Jan Nowak", level: 1 })).toBeVisible()
  await expect(page.getByRole("link", { name: "Odznaki 1" })).toBeVisible()
  await expect(page.getByRole("main").getByText("Głos grupy").first()).toBeVisible()

  await page.getByRole("main").getByRole("link", { name: /Odbierz/ }).first()
    .click()
  await page.getByRole("dialog").getByRole("button", { name: /Odbierz/ }).click()
  await expect(page.getByText("Odebrano odznakę „Głos grupy”.")).toBeVisible()
  await expect(page.getByRole("link", { name: "Odznaki 0" })).toBeVisible()
})

test("changes lives in the edit dialog", async({ page }) => {
  await page.getByRole("link", { name: /^Jan Nowak/ }).click()
  await page.getByRole("link", { name: "Edytuj" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("button", { name: "Zapisz" })).toBeDisabled()
  await dialog.getByRole("button", { name: "Dodaj życie" }).click()
  await dialog.getByRole("button", { name: "Dodaj życie" }).click()
  await expect(dialog.getByRole("group", { name: "Życia" }).getByRole("status")).toHaveText("5")
  await dialog.getByRole("button", { name: "Zapisz" }).click()

  await expect(page.getByText("Kometa ma teraz 5 żyć.")).toBeVisible()
})

test("removes a student from the group", async({ page }) => {
  await page.getByRole("link", { name: /^Ola Zielińska/ }).click()
  await page.getByRole("link", { name: "Edytuj" }).click()
  await page.getByRole("dialog").getByRole("link", { name: "Usuń z grupy" }).click()

  const dialog = page.getByRole("dialog").filter({ hasText: "Usunąć studenta z grupy?" })
  await expect(dialog).toContainText("Feniks straci dostęp do grupy")
  await dialog.getByRole("button", { name: "Usuń z grupy" }).click()

  await expect(page.getByText("Feniks nie należy już do grupy.")).toBeVisible()
  await expect(studentRow(page, "Ola Zielińska")).toHaveCount(0)
})

test("imports students from CSV by e-mail, skipping unknown accounts", async({ page, rails }) => {
  await rails.create("user", "student", { email: "marek.lis@example.com", "full_name": "Marek Lis" })

  await page.getByRole("link", { name: "Importuj z CSV" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.locator("input[type=file]").setInputFiles("e2e/fixtures/students.csv")
  await dialog.getByRole("button", { name: "Importuj" }).click()

  await expect(page.getByText("Dodano 1 studenta.")).toBeVisible()
  await expect(page.getByText("Pominięto 1 wiersz.")).toBeVisible()
  await expect(page.getByText("Nie znaleziono konta dla „nieznany@example.com”.")).toBeVisible()

  await page.goto(`/story_groups/${group.id}/students`)
  await expect(studentRow(page, "Marek Lis")).toContainText("„Lis”")
})
