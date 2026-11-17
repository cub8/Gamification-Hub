import { expect, test } from "@e2e/support/on-rails"

type Mail = { subject: string; text: string } | null

test("a teacher signs in with an e-mail link", async({ page, rails }) => {
  const email = "anna.kowalska@example.com"
  await rails.create("user", "teacher", { email, "full_name": "Anna Kowalska" })

  await page.goto("/")
  await expect(page).toHaveURL("/login")
  await page.getByRole("link", { name: "Zaloguj się e-mailem" }).click()
  await page.getByLabel("Adres e-mail").fill(email)
  await page.getByRole("button", { name: "Wyślij link" }).click()
  await expect(page.getByRole("heading", { name: "Sprawdź skrzynkę" })).toBeVisible()
  await expect(page.getByText(email)).toBeVisible()

  const mail = await rails.command<Mail>("last_mail", { to: email })
  const link = mail?.text.match(/https?:\/\/\S+\/auth\/passwordless\/verify\?token=\S+/)?.[0]
  expect(link).toBeTruthy()
  await page.goto(link!)

  await expect(page).toHaveURL("/home")
  await expect(page.getByText("Zalogowano pomyślnie.")).toBeVisible()
  await expect(page.getByRole("button", { name: "Konto: Anna Kowalska" })).toBeVisible()
})

test("an unknown address gets the same answer but no e-mail", async({ page, rails }) => {
  await page.goto("/auth/passwordless/new")
  await page.getByLabel("Adres e-mail").fill("nikt@example.com")
  await page.getByRole("button", { name: "Wyślij link" }).click()

  await expect(page.getByRole("heading", { name: "Sprawdź skrzynkę" })).toBeVisible()
  expect(await rails.command<Mail>("last_mail", { to: "nikt@example.com" })).toBeNull()
})

test("a used sign-in link does not work twice", async({ page, rails }) => {
  const user = await rails.create("user", "student")
  const path = await rails.command<string>("sign_in_path", { "user_id": user.id })
  await page.goto(path)
  await expect(page).toHaveURL("/home")

  await page.context().clearCookies()
  await page.goto(path)
  await expect(page).toHaveURL("/login")
  await expect(page.getByText("Nieprawidłowy token")).toBeVisible()
})

test("signs out", async({ page, rails, signIn }) => {
  await signIn(await rails.create("user", "teacher", { "full_name": "Anna Kowalska" }))
  await page.getByRole("button", { name: "Konto: Anna Kowalska" }).click()
  await page.getByRole("link", { name: "Wyloguj się" }).click()

  await expect(page).toHaveURL("/login")
  await page.goto("/home")
  await expect(page).toHaveURL("/login")
})

test("pages need a signed in user", async({ page }) => {
  await page.goto("/story_groups")
  await expect(page).toHaveURL("/login")
})
