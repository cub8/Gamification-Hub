import { expect, type Record, test } from "@e2e/support/on-rails"

type Mail = { subject: string; text: string } | null
let scenario: { [name: string]: Record }

test.beforeEach(async({ page, rails, signIn }) => {
  scenario = await rails.scenario("group")
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/teachers`)
})

test("the owner is listed", async({ page }) => {
  await expect(page.getByRole("main")).toContainText("Anna Kowalska anna.kowalska@example.com Właściciel")
})

test("adds a teacher from the same university and removes them", async({ page, rails }) => {
  await rails.create("user", "teacher", { "full_name": "Tomasz Wójcik", email: "tomasz.wojcik@example.com" })
  await page.getByRole("link", { name: "Dodaj nauczyciela" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.getByRole("searchbox", { name: "Szukaj nauczyciela" }).fill("Tomasz")
  await dialog.getByRole("button", { name: /Dodaj/ }).first().click()

  await expect(page.getByText("Dodano: Tomasz Wójcik.")).toBeVisible()
  await expect(page.getByRole("main")).toContainText("tomasz.wojcik@example.com")

  await page.getByRole("main").getByRole("link", { name: /Usuń/ }).first()
    .click()
  await page.getByRole("dialog").getByRole("button", { name: /Usuń/ }).click()
  await expect(page.getByText("Usunięto z grupy: Tomasz Wójcik.")).toBeVisible()
  await expect(page.getByRole("main")).not.toContainText("tomasz.wojcik@example.com")
})

test("invites a new teacher by e-mail", async({ page, rails }) => {
  await page.getByRole("link", { name: "Dodaj nauczyciela" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.getByLabel("Adres e-mail").fill("nowa.nauczycielka@example.com")
  await dialog.getByRole("button", { name: "Wyślij zaproszenie" }).click()

  await expect(page.getByText("Wysłano zaproszenie na adres nowa.nauczycielka@example.com.")).toBeVisible()
  await expect(page.getByRole("main")).toContainText("nowa.nauczycielka@example.com")
  const mail = await rails.command<Mail>("last_mail", { to: "nowa.nauczycielka@example.com" })
  expect(mail?.text).toContain("Klasa 3B")
})

test("cannot invite a student account as a teacher", async({ page }) => {
  await page.getByRole("link", { name: "Dodaj nauczyciela" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.getByLabel("Adres e-mail").fill("jan.nowak@example.com")
  await dialog.getByRole("button", { name: "Wyślij zaproszenie" }).click()

  await expect(page.getByText("To konto studenta. Zaprosić można tylko nauczyciela albo nowy adres e-mail."))
    .toBeVisible()
})

test("an invited teacher joins the group on first sign-in", async({ page, rails }) => {
  await page.getByRole("link", { name: "Dodaj nauczyciela" }).click()
  await page.getByRole("dialog").getByLabel("Adres e-mail").fill("nowa.nauczycielka@example.com")
  await page.getByRole("dialog").getByRole("button", { name: "Wyślij zaproszenie" }).click()
  await expect(page.getByText("Wysłano zaproszenie")).toBeVisible()

  const mail = await rails.command<Mail>("last_mail", { to: "nowa.nauczycielka@example.com" })
  const link = mail!.text.match(/https?:\/\/\S+\/auth\/teacher_invitations\/\S+/)![0]
  await page.context().clearCookies()
  await page.goto(link)

  await expect(page.getByText(/Dołączono jako nauczyciel do: Klasa 3B\./)).toBeVisible()
})
