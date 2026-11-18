import { type Page } from "@playwright/test"
import { expect, test } from "@e2e/support/on-rails"

async function inviteByEmail(page: Page, email: string) {
  await page.getByRole("link", { name: "Dodaj nauczyciela" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.getByLabel("Adres e-mail").fill(email)
  await dialog.getByRole("button", { name: "Wyślij zaproszenie" }).click()
}

test.beforeEach(async({ page, scenario, signIn }) => {
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

  await page.getByRole("main").getByRole("link", { name: /Usuń/ }).click()
  await page.getByRole("dialog").getByRole("button", { name: /Usuń/ }).click()
  await expect(page.getByText("Usunięto z grupy: Tomasz Wójcik.")).toBeVisible()
  await expect(page.getByRole("main")).not.toContainText("tomasz.wojcik@example.com")
})

test("invites a new teacher by e-mail, who joins the group on first sign-in", async({ page, rails }) => {
  const email = "nowa.nauczycielka@example.com"
  await inviteByEmail(page, email)

  await expect(page.getByText(`Wysłano zaproszenie na adres ${email}.`)).toBeVisible()
  await expect(page.getByRole("main")).toContainText(email)

  const link = (await rails.lastMail(email))!.match(/https?:\/\/\S+\/auth\/teacher_invitations\/\S+/)![0]
  await page.context().clearCookies()
  await page.goto(link)
  await expect(page.getByText("Dołączono jako nauczyciel do: Klasa 3B.")).toBeVisible()
})

test("cannot invite a student account as a teacher", async({ page }) => {
  await inviteByEmail(page, "jan.nowak@example.com")

  await expect(page.getByText("To konto studenta. Zaprosić można tylko nauczyciela albo nowy adres e-mail."))
    .toBeVisible()
})
