import { type Page } from "@playwright/test"
import { expect, type Record, test } from "@e2e/support/on-rails"

let scenario: { [name: string]: Record }

test.beforeEach(async({ page, rails, signIn }) => {
  scenario = await rails.scenario("group")
  await signIn(scenario.student)
  await page.goto(`/story_groups/${scenario.group.id}`)
})

test("a student sees the group from their side", async({ page }) => {
  await expect(page.getByRole("heading", { name: "Klasa 3B", level: 1 })).toBeVisible()
  await expect(page.getByRole("region", { name: "Grupa Klasa 3B" })).toContainText("Jesteś uczestnikiem")
  const sections = page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link")
  await expect(sections).toHaveText(["Przegląd", "Sklep", "Moje przedmioty", "Arkusze ocen", "Rangi", "Odznaki",
    "Historia waluty", "Ranking", "Ustawienia w grupie"])
  await expect(page.getByRole("link", { name: "Masz 50 do wydania, pokaż historię waluty" })).toBeVisible()
})

test("a student changes their nickname", async({ page }) => {
  await page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link", { name: "Ustawienia w grupie" }).click()
  await page.getByLabel("Twój pseudonim").fill("Meteor")
  await page.getByRole("button", { name: "Zapisz" }).click()

  await expect(page.getByText("Twój pseudonim w tej grupie: Meteor.")).toBeVisible()
  await expect(page.getByLabel("Twój pseudonim")).toHaveValue("Meteor")
})

test("a nickname must be unique within the group", async({ page }) => {
  await page.goto(`/story_groups/${scenario.group.id}/membership/edit`)
  await page.getByLabel("Twój pseudonim").fill("feniks")
  await page.getByRole("button", { name: "Zapisz" }).click()

  await expect(page.getByRole("alert").first()).toBeVisible()
  await page.reload()
  await expect(page.getByLabel("Twój pseudonim")).toHaveValue("Kometa")
})

async function leaveGroup(page: Page) {
  await page.goto(`/story_groups/${scenario.group.id}/membership/edit`)
  await page.getByRole("link", { name: "Opuść grupę" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Opuścić grupę Klasa 3B?" })).toBeVisible()
  // The page does not change after leaving (see the known bug below), so wait for the server instead.
  const left = page.waitForResponse((response) => response.url().endsWith("/membership"))
  await dialog.getByRole("button", { name: /Opuść/ }).click()
  await left
}

test("leaving the group removes the student from it", async({ page }) => {
  await leaveGroup(page)

  await page.goto("/story_groups")
  await expect(page.getByRole("main").getByRole("article")).toHaveCount(0)
})

// Known bug: the leave button submits into the "modal" frame, but StoryGroupMembershipsController#destroy
// answers with a plain redirect instead of redirect_outside_turbo_frame, so the student stays on the stale
// settings page and never sees the message.
test("after leaving, the student lands on the group list with a message", async({ page }) => {
  test.fail()
  await leaveGroup(page)

  await expect(page).toHaveURL("/story_groups")
  await expect(page.getByText("Opuszczono grupę Klasa 3B.")).toBeVisible()
})

test("a student sees their badges and the rank ladder", async({ page, rails }) => {
  const badge = await rails.command<Record>("scenarios/award_badge",
    { "membership_id": scenario.membership.id, badge: "Bez skazy" })
  expect(badge).toBeTruthy()

  await page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link", { name: "Odznaki" }).click()
  await expect(page.getByRole("main")).toContainText("Bez skazy")
  await page.getByRole("navigation", { name: "Sekcje grupy" }).getByRole("link", { name: "Rangi" }).click()
  await expect(page.getByRole("main")).toContainText("Adept")
  await expect(page.getByRole("main")).toContainText("Ekspert")
})

test("a student cannot open the teacher's screens", async({ page }) => {
  for (const path of ["/items/new", "/students", "/edit", "/invites", "/teachers", "/export"]) {
    await page.goto(`/story_groups/${scenario.group.id}${path}`)
    await expect(page, `student must not reach ${path}`).not.toHaveURL(new RegExp(`${path}$`))
  }
})

test("a student of another group cannot open this one", async({ page, rails, signIn }) => {
  const outsider = await rails.create("user", "student")
  await signIn(outsider)
  await page.goto(`/story_groups/${scenario.group.id}`)
  await expect(page.getByRole("heading", { name: "Klasa 3B", level: 1 })).toHaveCount(0)
})
