import fs from "node:fs"
import { choose, expect, type Record, test } from "@e2e/support/on-rails"

let scenario: { [name: string]: Record }

test.beforeEach(async({ page, rails, signIn }) => {
  scenario = await rails.scenario("group")
  await signIn(scenario.teacher)
  await page.goto(`/story_groups/${scenario.group.id}/edit`)
})

test("edits the group's name, story, art, currency and starting lives", async({ page }) => {
  await page.getByLabel("Nazwa grupy").fill("Klasa 4B")
  await page.getByLabel("Opowieść").fill("Nowy rozdział")
  await choose(page.getByRole("radio", { name: "Grafika grupy: Morze" }))
  await page.getByLabel("Nazwa waluty").fill("Pereł")
  await choose(page.getByRole("radio", { name: "Ikona waluty: Perła" }))
  await page.getByRole("group", { name: "Życia na start" }).getByRole("button", { name: "Więcej" }).click()
  await expect(page.getByRole("group", { name: "Życia na start" }).getByRole("status")).toHaveText("4")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByText("Zapisano ustawienia grupy.")).toBeVisible()
  await expect(page.getByLabel("Nazwa grupy")).toHaveValue("Klasa 4B")
  await expect(page.getByLabel("Nazwa waluty")).toHaveValue("Pereł")
  await expect(page.getByRole("radio", { name: "Grafika grupy: Morze" })).toBeChecked()
  await expect(page.getByRole("group", { name: "Życia na start" }).getByRole("status")).toHaveText("4")
  await expect(page.getByRole("region", { name: "Grupa Klasa 4B" })).toBeVisible()

  await page.getByRole("link", { name: "Wróć do grupy" }).click()
  await expect(page.getByRole("heading", { name: "Klasa 4B", level: 1 })).toBeVisible()
  await expect(page.getByText("Nowy rozdział")).toBeVisible()
})

test("does not save a group without a name", async({ page }) => {
  await page.getByLabel("Nazwa grupy").fill("")
  await page.getByRole("button", { name: "Zapisz zmiany" }).click()

  await expect(page.getByRole("alert").first()).toBeVisible()
  await page.reload()
  await expect(page.getByLabel("Nazwa grupy")).toHaveValue("Klasa 3B")
})

test("deletes the group only after typing its name", async({ page }) => {
  await page.getByRole("link", { name: "Usuń grupę" }).click()
  const dialog = page.getByRole("dialog")
  await expect(dialog.getByRole("heading", { name: "Usunąć grupę na zawsze?" })).toBeVisible()
  await expect(dialog).toContainText("3 studenci i 1 nauczyciel stracą dostęp.")

  const remove = dialog.getByRole("button", { name: "Usuń grupę" })
  await expect(remove).toBeDisabled()
  await dialog.getByRole("textbox").fill("Klasa 3")
  await expect(remove).toBeDisabled()
  await dialog.getByRole("textbox").fill("Klasa 3B")
  await remove.click()

  await expect(page).toHaveURL("/story_groups")
  await expect(page.getByText("Usunięto grupę Klasa 3B.")).toBeVisible()
  await expect(page.getByRole("main").getByRole("article")).toHaveCount(0)
})

test("exports the configuration as CSV files", async({ page }) => {
  await page.goto(`/story_groups/${scenario.group.id}/export`)
  const exportButton = page.getByRole("button", { name: "Eksportuj" })
  await expect(exportButton).toBeDisabled()

  await choose(page.getByRole("switch", { name: "Rangi" }))
  await choose(page.getByRole("switch", { name: "Przedmioty" }))
  const downloads: string[] = []
  page.on("download", async(download) => downloads.push(download.suggestedFilename()))
  const ranks = page.waitForEvent("download", (download) => download.suggestedFilename() === "ranks.csv")
  const items = page.waitForEvent("download", (download) => download.suggestedFilename() === "items.csv")
  await exportButton.click()

  const ranksCsv = fs.readFileSync(await (await ranks).path(), "utf8")
  expect(ranksCsv).toContain("nazwa,próg_waluty,zniżka,ikona")
  expect(ranksCsv).toContain("Adept,40,5,shield")
  expect(fs.readFileSync(await (await items).path(), "utf8")).toContain("Konsultacja")
  expect(downloads.sort()).toEqual(["items.csv", "ranks.csv"])
})

test("an exported group can seed a new one", async({ page }) => {
  await page.goto(`/story_groups/${scenario.group.id}/export`)
  for (const name of ["Rangi", "Odznaki", "Przedmioty", "Szablony kategorii zajęć"]) {
    await choose(page.getByRole("switch", { name }))
  }
  const files = new Map<string, string>()
  const allDownloaded = new Promise<void>((resolve) => {
    page.on("download", async(download) => {
      files.set(download.suggestedFilename(), await download.path())
      if (files.size === 4) resolve()
    })
  })
  await page.getByRole("button", { name: "Eksportuj" }).click()
  await allDownloaded

  await page.goto("/story_groups/new")
  await page.getByLabel("Nazwa grupy").fill("Kopia 3B")
  await page.getByRole("button", { name: "Dalej" }).click()
  await page.getByLabel("Nazwa waluty").fill("Monet")
  await page.getByRole("button", { name: "Dalej" }).click()
  await choose(page.getByRole("radio", { name: /Z plików CSV/ }))
  const inputs = { ranks: "ranks.csv", badges: "badges.csv", items: "items.csv", templates: "templates.csv" }
  for (const [resource, file] of Object.entries(inputs)) {
    expect(files.has(file), `${file} was downloaded`).toBeTruthy()
    await page.locator(`input[type=file][name="setup[csv][${resource}]"][data-resource]`).setInputFiles({
      name: file, mimeType: "text/csv", buffer: fs.readFileSync(files.get(file)!),
    })
    await page.getByRole("dialog").getByRole("button", { name: "Zatwierdź" }).click()
  }
  await page.getByRole("button", { name: "Dalej" }).click()
  await page.getByRole("button", { name: "Utwórz grupę z importu" }).click()

  await expect(page.getByText("Utworzono 5 rang, 6 odznak, 7 przedmiotów oraz 8 kategorii")).toBeVisible()
})
