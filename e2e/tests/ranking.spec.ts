import { type Page } from "@playwright/test"
import { choose, expect, test } from "@e2e/support/on-rails"

async function showRanking(page: Page, mode: "Podium i własne miejsce" | "Pełny ranking") {
  await page.getByRole("switch", { name: "Widoczny dla studentów" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Pokazać ranking studentom?" })).toBeVisible()
  await choose(dialog.getByRole("radio", { name: new RegExp(`^${mode}`) }))
  await dialog.getByRole("button", { name: "Pokaż ranking" }).click()
}

test("the teacher sees everyone, ordered by collected currency", async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/ranking`)

  const rows = page.getByRole("table", { name: "Ranking" }).getByRole("row")
  await expect(rows.nth(1)).toHaveAccessibleName("Miejsce 1 Kometa Jan Nowak Adept 50")
  await expect(rows.nth(2)).toHaveAccessibleName("Miejsce 2 Feniks Ola Zielińska Nowicjusz 10")
  await expect(rows.nth(3)).toHaveAccessibleName("Miejsce 3 Piotr Wiśniewski Bez pseudonimu Nowicjusz 0")
})

test("students see the podium only after the teacher shows the ranking", async({ page, scenario, signIn }) => {
  const { group, teacher, student } = scenario
  await signIn(student)
  await page.goto(`/story_groups/${group.id}/ranking`)
  await expect(page.getByRole("heading", { name: "Ranking jest teraz ukryty" })).toBeVisible()

  await signIn(teacher)
  await page.goto(`/story_groups/${group.id}/ranking`)
  await showRanking(page, "Podium i własne miejsce")
  await expect(page.getByText("Ranking widoczny: podium i własne miejsce.")).toBeVisible()
  await expect(page.getByRole("switch", { name: "Widoczny dla studentów" })).toBeChecked()

  await signIn(student)
  await page.goto(`/story_groups/${group.id}/ranking`)
  await expect(page.getByRole("heading", { name: "Ranking jest teraz ukryty" })).toHaveCount(0)
  await expect(page.getByRole("main")).toContainText("Kometa")
  await expect(page.getByRole("main")).toContainText("Feniks")
  // Students see nicknames, never the real names of others.
  await expect(page.getByRole("main")).not.toContainText("Ola Zielińska")
})

test("the teacher shows the full ranking and hides it again", async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/ranking`)
  await showRanking(page, "Pełny ranking")
  await expect(page.getByText("Ranking widoczny w całości.")).toBeVisible()

  await page.getByRole("switch", { name: "Widoczny dla studentów" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Ukryć ranking przed studentami?" })).toBeVisible()
  await dialog.getByRole("button", { name: "Ukryj ranking" }).click()
  await expect(page.getByText("Ranking ukryty przed studentami.")).toBeVisible()
  await expect(page.getByRole("switch", { name: "Widoczny dla studentów" })).not.toBeChecked()
})
