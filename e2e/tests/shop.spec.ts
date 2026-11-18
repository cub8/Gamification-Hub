import { card, expect, test } from "@e2e/support/on-rails"

test("a student buys an item, which the teacher then sees", async({ page, scenario, signIn }) => {
  const { group, student, teacher } = scenario
  await signIn(student)
  await page.goto(`/story_groups/${group.id}/shop`)
  await expect(page.getByText("Masz 50 do wydania.")).toBeVisible()
  await expect(page.getByRole("heading", { name: "Stać cię teraz 6" })).toBeVisible()

  await card(page, "Konsultacja").getByRole("link", { name: "Kup Konsultacja za 17" }).click()
  await page.getByRole("dialog").getByRole("button", { name: /Kup/ }).click()

  await expect(page.getByText("Kupione: „Konsultacja”. Zostało Ci 33")).toBeVisible()
  await expect(page.getByText("Masz 33 do wydania.")).toBeVisible()

  const sections = page.getByRole("navigation", { name: "Sekcje grupy" })
  await sections.getByRole("link", { name: "Moje przedmioty" }).click()
  await expect(page.getByText("1 przedmiot.")).toBeVisible()
  await expect(page.getByRole("main").getByText("Konsultacja").first()).toBeVisible()
  await sections.getByRole("link", { name: "Historia waluty" }).click()
  await expect(page.getByRole("main")).toContainText("Konsultacja")

  await signIn(teacher)
  await page.goto(`/story_groups/${group.id}`)
  await expect(page.getByRole("region", { name: "Ostatnie zakupy" })).toContainText("Konsultacja")
  await page.goto("/notifications")
  await expect(page.getByRole("main")).toContainText("Konsultacja")
})

test("items above the student's rank are sealed", async({ page, scenario, signIn }) => {
  await signIn(scenario.student)
  await page.goto(`/story_groups/${scenario.group.id}/shop`)

  const sealed = card(page, "+0.5 oceny końcowej")
  await expect(page.getByRole("heading", { name: "Zapieczętowane 1" })).toBeVisible()
  await expect(sealed).toContainText("Wymaga rangi Ekspert")
  await expect(sealed.getByRole("link", { name: /^Kup/ })).toHaveCount(0)
})

test("a student who cannot afford anything sees no offer to buy", async({ page, scenario, signIn }) => {
  await signIn(scenario.others[0])
  await page.goto(`/story_groups/${scenario.group.id}/shop`)

  await expect(page.getByText("Masz 10 do wydania.")).toBeVisible()
  await expect(page.getByRole("main").getByRole("link", { name: /^Kup/ })).toHaveCount(0)
})

test("at zero lives only items marked for it can be bought", async({ page, rails, scenario, signIn }) => {
  const membership = await rails.create("story_group_student",
    { "story_group_id": scenario.group.id, lives: 0, "current_currency": 100, "total_currency": 100 })
  await signIn({ id: membership.user_id as number })
  await page.goto(`/story_groups/${scenario.group.id}/shop`)

  await expect(page.getByRole("main").getByRole("link", { name: /^Kup/ })).toHaveCount(1)
  await expect(card(page, "1up: odzyskanie życia").getByRole("link", { name: /^Kup/ })).toBeVisible()
})
