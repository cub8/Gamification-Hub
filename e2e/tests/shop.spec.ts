import { type Page } from "@playwright/test"
import { expect, type Record, test } from "@e2e/support/on-rails"

let scenario: { [name: string]: Record }

const offer = (page: Page, name: string) => page.getByRole("main").getByRole("article").filter({ has: page.getByRole("heading", { name, exact: true }) })

test.beforeEach(async({ rails }) => {
  scenario = await rails.scenario("group")
})

test("a student buys an item, which the teacher then sees", async({ page, signIn }) => {
  const { group, student, teacher } = scenario
  await signIn(student)
  await page.goto(`/story_groups/${group.id}/shop`)
  await expect(page.getByText("Masz 50 do wydania.")).toBeVisible()
  await expect(page.getByRole("heading", { name: "Stać cię teraz 6" })).toBeVisible()

  // Adept gives −5% on this item, so the 11 becomes 10.
  await offer(page, "Konsultacja").getByRole("link", { name: /^Kup Konsultacja za/ }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog).toContainText("Konsultacja")
  await dialog.getByRole("button", { name: /Kup/ }).click()

  await expect(page.getByText(/Kupione: „Konsultacja”\. Zostało Ci \d+/)).toBeVisible()
  const balance = Number((await page.getByText(/Masz \d+ do wydania\./).textContent())!.match(/\d+/)![0])
  expect(balance).toBeLessThan(50)
  expect(balance).toBeGreaterThanOrEqual(50 - 17)

  await page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link", { name: "Moje przedmioty" }).click()
  await expect(page.getByText("1 przedmiot.")).toBeVisible()
  await expect(page.getByRole("main").getByText("Konsultacja").first()).toBeVisible()

  await page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link", { name: "Historia waluty" }).click()
  await expect(page.getByRole("main")).toContainText("Konsultacja")

  await signIn(teacher)
  await page.goto(`/story_groups/${group.id}`)
  await expect(page.getByRole("region", { name: "Ostatnie zakupy" })).toContainText("Konsultacja")
  await page.goto("/notifications")
  await expect(page.getByRole("main")).toContainText("Konsultacja")
})

test("items above the student's rank are sealed", async({ page, signIn }) => {
  await signIn(scenario.student)
  await page.goto(`/story_groups/${scenario.group.id}/shop`)

  const sealed = offer(page, "+0.5 oceny końcowej")
  await expect(page.getByRole("heading", { name: "Zapieczętowane 1" })).toBeVisible()
  await expect(sealed).toContainText("Wymaga rangi Ekspert")
  await expect(sealed.getByRole("link", { name: /^Kup/ })).toHaveCount(0)
})

test("a student who cannot afford anything sees no offer to buy", async({ page, signIn }) => {
  await signIn(scenario.others[0] as unknown as Record)
  await page.goto(`/story_groups/${scenario.group.id}/shop`)

  await expect(page.getByText("Masz 10 do wydania.")).toBeVisible()
  await expect(page.getByRole("main").getByRole("link", { name: /^Kup/ })).toHaveCount(0)
})

test("at zero lives only items marked for it can be bought", async({ page, rails, signIn }) => {
  const { student } = await rails.command<{ student: Record }>("scenarios/group_student",
    { "group_id": scenario.group.id, lives: 0, currency: 100 })
  await signIn(student)
  await page.goto(`/story_groups/${scenario.group.id}/shop`)

  await expect(page.getByRole("main").getByRole("link", { name: /^Kup/ })).toHaveCount(1)
  await expect(offer(page, "1up: odzyskanie życia").getByRole("link", { name: /^Kup/ })).toBeVisible()
})
