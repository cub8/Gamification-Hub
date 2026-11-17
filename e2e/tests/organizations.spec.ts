import { expect, type Record, test } from "@e2e/support/on-rails"

type Mail = { subject: string; text: string } | null
let organization: Record
let orgAdmin: Record

test.beforeEach(async({ rails }) => {
  organization = await rails.create("organization", { name: "Uniwersytet Testowy", "max_members": 3 })
  orgAdmin = await rails.create("user", "organization_admin", { "full_name": "Olga Admin", email: "olga.admin@example.com", "organization_id": organization.id })
})

test.describe("as the global admin", () => {
  test.beforeEach(async({ rails, signIn }) => {
    await signIn(await rails.create("user", "global_admin", { "full_name": "Grażyna Admin" }))
  })

  test("the home page summarises the organizations", async({ page }) => {
    await expect(page.getByRole("heading", { name: "Dzień dobry, Grażyna" })).toBeVisible()
    await expect(page.getByRole("region", { name: "Organizacje" })).toContainText("Uniwersytet Testowy")
    await expect(page.getByRole("region", { name: "Podsumowanie organizacji" }).getByRole("definition")).toHaveText(["1", "1", "2", "0"])
  })

  test("creates an organization", async({ page }) => {
    await page.goto("/organizations")
    await page.getByRole("link", { name: "Utwórz organizację" }).click()
    await page.getByLabel("Nazwa").fill("Politechnika Testowa")
    await page.getByLabel("Limit członków").fill("40")
    await page.getByRole("button", { name: "Utwórz organizację" }).click()

    await expect(page.getByText("Pomyślnie utworzono organizację.")).toBeVisible()
    await expect(page.getByRole("heading", { name: "Politechnika Testowa", level: 1 })).toBeVisible()
    await expect(page.getByText("0 z 40 miejsc zajętych")).toBeVisible()
  })

  test("does not create an organization without a name", async({ page }) => {
    await page.goto("/organizations/new")
    await page.getByLabel("Limit członków").fill("40")
    await page.getByRole("button", { name: "Utwórz organizację" }).click()

    await expect(page.getByRole("alert").first()).toBeVisible()
    await expect(page.getByRole("heading", { name: "Nowa organizacja" })).toBeVisible()
    await page.goto("/organizations")
    // A nameless organization would be listed by its seats alone.
    await expect(page.getByRole("main").getByRole("link", { name: /^0 \/ 40/ })).toHaveCount(0)
  })

  test("edits an organization's member limit", async({ page }) => {
    await page.goto(`/organizations/${organization.id}`)
    await page.getByRole("link", { name: "Edytuj" }).click()
    await page.getByLabel("Limit członków").fill("10")
    await page.getByRole("button", { name: /Zapisz/ }).click()

    await expect(page.getByText("Pomyślnie zaktualizowano organizację.")).toBeVisible()
    await expect(page.getByText("1 z 10 miejsc zajętych")).toBeVisible()
  })

  test("invites an organization admin, who completes their account on first sign-in", async({ page, rails }) => {
    await page.goto(`/organizations/${organization.id}`)
    await page.getByRole("link", { name: "Dodaj administratora" }).click()
    await page.getByLabel("Adres e-mail").fill("nowy.admin@example.com")
    await page.getByRole("button", { name: "Wyślij zaproszenie" }).click()

    await expect(page.getByText("Pomyślnie dodano administratora organizacji. Wysłano zaproszenie na email."))
      .toBeVisible()
    await expect(page.getByRole("main")).toContainText("nowy.admin@example.com")

    const mail = await rails.command<Mail>("last_mail", { to: "nowy.admin@example.com" })
    // The invitation carries a sign-in link, so the first click signs the new admin in.
    const link = mail!.text.match(/https?:\/\/\S+\/auth\/passwordless\/verify\?token=\S+/)![0]
    await page.context().clearCookies()
    await page.goto(link)

    await expect(page.getByRole("heading", { name: "Uzupełnij swoje dane" })).toBeVisible()
    await expect(page.getByLabel("Adres e-mail")).toHaveValue("nowy.admin@example.com")
    await page.getByLabel("Imię i nazwisko").fill("Nowy Admin")
    await page.getByRole("button", { name: "Zapisz i przejdź dalej" }).click()

    await expect(page.getByText("Pomyślnie skonfigurowano konto.")).toBeVisible()
    await expect(page.getByRole("heading", { name: "Dzień dobry, Nowy" })).toBeVisible()
  })

  test("removes an organization admin", async({ page }) => {
    await page.goto(`/organizations/${organization.id}`)
    await page.getByRole("link", { name: "Usuń: Olga Admin" }).click()
    await page.getByRole("dialog").getByRole("button", { name: /Usuń/ }).click()

    await expect(page.getByText("Usunięto administratora: Olga Admin.")).toBeVisible()
    await expect(page.getByRole("main")).not.toContainText("olga.admin@example.com")
  })

  test("deletes an organization after typing its name", async({ page }) => {
    await page.goto(`/organizations/${organization.id}`)
    await page.getByRole("link", { name: "Usuń organizację" }).click()
    const dialog = page.getByRole("dialog")
    const remove = dialog.getByRole("button", { name: /Usuń/ })
    await expect(remove).toBeDisabled()
    await dialog.getByRole("textbox").fill("Uniwersytet Testowy")
    await remove.click()

    await expect(page.getByText("Usunięto organizację Uniwersytet Testowy.")).toBeVisible()
    await expect(page).toHaveURL("/organizations")
  })
})

test.describe("as an organization admin", () => {
  test.beforeEach(async({ signIn }) => {
    await signIn(orgAdmin)
  })

  test("the home page shows the organization's seats", async({ page }) => {
    await expect(page.getByRole("heading", { name: "Dzień dobry, Olga" })).toBeVisible()
    await expect(page.getByText("1 z 3 miejsc zajętych · 2 wolne")).toBeVisible()
  })

  test("adds a teacher, edits and removes them", async({ page, rails }) => {
    await page.getByRole("link", { name: "Dodaj użytkownika" }).click()
    await page.getByLabel("Adres e-mail").fill("tomasz.wojcik@example.com")
    await page.getByLabel("Imię i nazwisko").fill("Tomasz Wójcik")
    await page.getByLabel("Rola").selectOption({ label: "Nauczyciel" })
    await page.getByRole("button", { name: "Wyślij zaproszenie" }).click()

    await expect(page.getByText("Pomyślnie dodano użytkownika do organizacji. Wysłano zaproszenie na email."))
      .toBeVisible()
    expect(await rails.command<Mail>("last_mail", { to: "tomasz.wojcik@example.com" })).not.toBeNull()

    await page.goto(`/organizations/${organization.id}`)
    const main = page.getByRole("main")
    await expect(main).toContainText("Tomasz Wójcik")
    await expect(page.getByText("2 z 3 miejsc zajętych")).toBeVisible()

    await main.getByRole("link", { name: /Edytuj/ }).first().click()
    await page.getByLabel("Imię i nazwisko").fill("Tomasz Wójcik-Nowak")
    await page.getByRole("button", { name: /Zapisz/ }).click()
    await expect(page.getByText("Zapisano zmiany: Tomasz Wójcik-Nowak.")).toBeVisible()

    await page.goto(`/organizations/${organization.id}`)
    await main.getByRole("link", { name: /Usuń/ }).first().click()
    await page.getByRole("dialog").getByRole("button", { name: /Usuń/ }).click()
    await expect(page.getByText("Usunięto użytkownika: Tomasz Wójcik-Nowak.")).toBeVisible()
  })

  test("cannot add more users than the organization has seats", async({ page, rails }) => {
    await rails.create("user", "student", { "organization_id": organization.id })
    await rails.create("user", "student", { "organization_id": organization.id })

    await page.goto(`/organizations/${organization.id}/new_user`)
    await page.getByLabel("Adres e-mail").fill("za.duzo@example.com")
    await page.getByLabel("Imię i nazwisko").fill("Za Dużo")
    await page.getByRole("button", { name: "Wyślij zaproszenie" }).click()

    await expect(page.getByRole("alert").first()).toBeVisible()
    expect(await rails.command<Mail>("last_mail", { to: "za.duzo@example.com" })).toBeNull()
  })

  test("cannot manage other organizations", async({ page }) => {
    await page.goto("/organizations/new")
    await expect(page.getByRole("button", { name: "Utwórz organizację" })).toHaveCount(0)
  })
})
