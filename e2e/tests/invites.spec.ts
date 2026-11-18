import { type Page } from "@playwright/test"
import { expect, type Rails, type Record, test } from "@e2e/support/on-rails"

async function createCode(rails: Rails, group: Record, attributes = {}) {
  const invite = await rails.create("story_group_invite", { "story_group_id": group.id, ...attributes })
  return invite.code as string
}

async function enterCode(page: Page, code: string) {
  await page.goto("/join/new")
  await page.getByRole("textbox", { name: "Znak 1 z 6" }).pressSequentially(code)
  await page.getByRole("button", { name: "Dalej" }).click()
}

test("a teacher creates a code and a new student joins with it", async({ page, rails, scenario, signIn }) => {
  const { group, teacher } = scenario
  await signIn(teacher)
  await page.goto(`/story_groups/${group.id}/invites`)
  await expect(page.getByText("Brak aktywnych zaproszeń.")).toBeVisible()
  await page.getByRole("link", { name: "Nowe zaproszenie" }).click()
  await page.getByRole("dialog").getByRole("button", { name: "Utwórz zaproszenie" }).click()

  const flash = page.getByRole("status").filter({ hasText: "Utworzono kod" })
  const code = (await flash.textContent())!.match(/Utworzono kod (\w{6})/)![1]
  await expect(page.getByRole("main")).toContainText(`${code} Aktywne`)

  await signIn(await rails.create("user", "student", { email: "marek.lis@example.com", "full_name": "Marek Lis" }))
  await enterCode(page, code)

  await expect(page.getByRole("heading", { name: "Dołączasz do grupy Klasa 3B" })).toBeVisible()
  await page.getByLabel("Pseudonim w tej grupie").fill("Lis")
  await page.getByRole("button", { name: "Dołącz do grupy" }).click()

  await expect(page.getByRole("heading", { name: "Dołączono do grupy Klasa 3B" })).toBeVisible()
  await expect(page.getByText("Prowadzi Anna Kowalska.")).toBeVisible()
  await expect(page.getByText("Walutą w tej grupie są Złote monety.")).toBeVisible()
  await page.getByRole("link", { name: "Gotowe" }).click()
  await expect(page.getByRole("heading", { name: "Klasa 3B", level: 1 })).toBeVisible()

  // The teacher sees the newcomer, who got the group's starting lives.
  await signIn(teacher)
  await page.goto(`/story_groups/${group.id}/students`)
  const row = page.getByRole("main").getByRole("listitem").filter({ hasText: "Marek Lis" })
  await expect(row).toContainText("„Lis”")
  await expect(row.getByRole("button", { name: "Odbierz życie: Marek Lis" })).toBeEnabled()
  await page.goto(`/story_groups/${group.id}/invites`)
  await expect(page.getByRole("main")).toContainText("1, bez limitu")
})

test("a student who already belongs to the group is told so", async({ page, rails, scenario, signIn }) => {
  const code = await createCode(rails, scenario.group)
  await signIn(scenario.student)
  await enterCode(page, code)

  await expect(page.getByText("Już należysz do tej grupy.")).toBeVisible()
  await page.getByRole("link", { name: "Otwórz grupę" }).click()
  await expect(page.getByRole("heading", { name: "Klasa 3B", level: 1 })).toBeVisible()
})

for (const [label, attributes, message] of [
  ["an expired code", { "expires_at": "2020-01-01T00:00:00Z" }, "Ten kod wygasł. Poproś prowadzącego o nowy."],
  ["a used up code", { "max_uses": 1, "uses": 1 },
    "Z tego kodu skorzystała już maksymalna liczba osób. Poproś prowadzącego o nowy."],
] as const) {
  test(`rejects ${label}`, async({ page, rails, scenario, signIn }) => {
    const code = await createCode(rails, scenario.group, attributes)
    await signIn(await rails.create("user", "student"))
    await enterCode(page, code)

    await expect(page.getByText(message)).toBeVisible()
    await expect(page.getByRole("heading", { name: "Dołącz do grupy" })).toBeVisible()
  })
}

test("rejects an unknown code", async({ page, rails, signIn }) => {
  await signIn(await rails.create("user", "student"))
  await enterCode(page, "ABCDEF")

  await expect(page.getByText("Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.")).toBeVisible()
})

test("a teacher limits a code and then deletes it", async({ page, scenario, signIn }) => {
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/invites`)
  await page.getByRole("link", { name: "Nowe zaproszenie" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.getByRole("switch", { name: "Limit użyć" }).check()
  await dialog.getByRole("spinbutton").first().fill("25")
  await dialog.getByRole("button", { name: "Utwórz zaproszenie" }).click()

  await expect(page.getByRole("main")).toContainText("0 z 25")

  await page.getByRole("main").getByRole("link", { name: /^Usuń zaproszenie/ }).click()
  await page.getByRole("dialog").getByRole("button", { name: /Usuń/ }).click()
  await expect(page.getByText(/Usunięto zaproszenie \w{6}\./)).toBeVisible()
  await expect(page.getByText("Brak aktywnych zaproszeń.")).toBeVisible()
})

test("a teacher shows the code to the class and edits it", async({ page, rails, scenario, signIn }) => {
  const code = await createCode(rails, scenario.group)
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/invites`)
  await expect(page.getByRole("main")).toContainText(`${code} Aktywne Użycia: 0 z 10`)

  await page.getByRole("link", { name: "Pokaż" }).click()
  const shown = page.getByRole("dialog")
  await expect(shown.getByRole("heading", { name: "Dołącz do grupy Klasa 3B" })).toBeVisible()
  await expect(shown.getByRole("button", { name: `Drukuj kod ${code}` })).toBeVisible()
  await shown.getByRole("button", { name: "Zamknij" }).click()
  await expect(shown).toBeHidden()

  await page.getByRole("link", { name: `Edytuj zaproszenie ${code}` }).click()
  await page.getByRole("dialog").getByRole("spinbutton").first()
    .fill("40")
  await page.getByRole("dialog").getByRole("button", { name: /Zapisz/ }).click()
  await expect(page.getByText(`Zapisano zaproszenie ${code}.`)).toBeVisible()
  await expect(page.getByRole("main")).toContainText("0 z 40")
})
