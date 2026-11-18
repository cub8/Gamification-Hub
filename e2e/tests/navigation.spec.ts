import { expect, test } from "@e2e/support/on-rails"

test("a teacher's home lists their groups", async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await expect(page.getByRole("heading", { name: "Dzień dobry, Anna" })).toBeVisible()
  await page.getByRole("link", { name: "Klasa 3B Prowadzisz, 3 studentów" }).click()
  await expect(page.getByRole("heading", { name: "Klasa 3B", level: 1 })).toBeVisible()
})

test("a student's home shows their standing in each group", async({ page, scenario, signIn }) => {
  await signIn(scenario.student)
  await expect(page.getByRole("heading", { name: "Cześć, Jan" })).toBeVisible()
  const card = page.getByRole("main").getByRole("article").filter({ hasText: "Klasa 3B" })
  await expect(card.getByRole("definition")).toHaveText([/50\s*Złote monety/, /^\s*3\s*$/, /50 z 65 do rangi Ekspert/, /0\s*z 6/])
  await card.getByRole("link", { name: "Sklep" }).click()
  await expect(page.getByRole("heading", { name: "Sklep", level: 1 })).toBeVisible()
})

test("the group list can be searched", async({ page, rails, scenario, signIn }) => {
  await rails.create("story_group", { "owner_id": scenario.teacher.id, name: "Programowanie obiektowe" })
  await signIn(scenario.teacher)
  await page.goto("/story_groups")
  const cards = page.getByRole("main").getByRole("article")
  await expect(cards).toHaveCount(2)

  await page.getByRole("searchbox", { name: "Szukaj grupy" }).fill("obiekt")
  await expect(cards.filter({ visible: true })).toHaveCount(1)
  await expect(cards.filter({ visible: true })).toContainText("Programowanie obiektowe")
})

test("the group switcher jumps between groups", async({ page, rails, scenario, signIn }) => {
  await rails.create("story_group", { "owner_id": scenario.teacher.id, name: "Programowanie obiektowe" })
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}`)
  await page.getByRole("button", { name: "Zmień grupę" }).click()
  await page.getByRole("dialog").getByRole("link", { name: /Programowanie obiektowe/ }).click()

  await expect(page.getByRole("heading", { name: "Programowanie obiektowe", level: 1 })).toBeVisible()
})

test("switches the interface to English and back", async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.getByRole("button", { name: "Konto: Anna Kowalska" }).click()
  await page.getByRole("button", { name: "Zmień język na angielski" }).click()

  await expect(page.getByRole("heading", { name: "Good morning, Anna" })).toBeVisible()
  await page.goto(`/story_groups/${scenario.group.id}/items`)
  await expect(page.getByRole("heading", { name: "Items", level: 1 })).toBeVisible()

  await page.getByRole("button", { name: "Account: Anna Kowalska" }).click()
  await page.getByRole("button", { name: /Polish/ }).click()
  await expect(page.getByRole("heading", { name: "Przedmioty", level: 1 })).toBeVisible()
})

test("switches to the dark theme and remembers it", async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.getByRole("button", { name: "Przełącz motyw" }).click()
  await expect(page.locator("html")).toHaveAttribute("data-gh-theme", "dark")

  await page.reload()
  await expect(page.locator("html")).toHaveAttribute("data-gh-theme", "dark")
})

test("a student is told about a badge they were awarded", async({ page, scenario, signIn }) => {
  const { teacher, student, group, membership } = scenario
  await signIn(teacher)
  await page.goto(`/story_groups/${group.id}/students/${membership.id}/badges/new`)
  await page.getByRole("radio", { name: /^Bez skazy/ }).check({ force: true })
  await page.getByRole("button", { name: /Przyznaj/ }).click()
  await expect(page.getByText("Przyznano odznakę „Bez skazy”.")).toBeVisible()

  await signIn(student)
  await page.goto(`/story_groups/${group.id}`)
  await expect(page.getByRole("heading", { name: "Odznaki 1 z 6" })).toBeVisible()
  await expect(page.getByRole("article", { name: /Odznaka Bez skazy(?!, jeszcze niezdobyta)/ })).toBeVisible()
})

test("a teacher reads and clears purchase notifications", async({ page, rails, scenario, signIn }) => {
  await rails.scenario("purchase", { "membership_id": scenario.membership.id, item: "Konsultacja" })
  await signIn(scenario.teacher)

  await expect(page.getByRole("region", { name: "Ostatnie zakupy" }).getByRole("list")).toMatchAriaSnapshot(`
    - listitem: /Konsultacja Jan Nowak Klasa 3B/
  `)

  await page.goto("/notifications")
  const main = page.getByRole("main")
  await expect(main).toContainText("Konsultacja")
  await main.getByRole("button", { name: /Oznacz/ }).click()
  await expect(main.getByRole("button", { name: /Oznacz/ })).toHaveCount(0)
})
