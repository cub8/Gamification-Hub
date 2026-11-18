import { test as base, expect, type APIRequestContext, type Locator, type Page } from "@playwright/test"

export { expect }

export type Record = { id: number; [attribute: string]: unknown }

// What e2e/app_commands/scenarios/group.rb builds.
export type GroupScenario = {
  teacher: Record
  group: Record
  student: Record
  membership: Record
  others: Record[]
}

// Talks to the test server through cypress-on-rails: e2e/app_commands/<name>.rb.
export class Rails {
  constructor(private readonly request: APIRequestContext) {}

  async command<T = unknown>(name: string, options: unknown = {}): Promise<T> {
    const response = await this.request.post("/__e2e__/command", { data: { name, options } })
    expect(response.ok(), await response.text()).toBeTruthy()

    const [result] = await response.json()
    return result
  }

  // create("user", "teacher", { email: "a@b.pl" }) is FactoryBot.create(:user, :teacher, email: "a@b.pl").
  create(factory: string, ...traitsAndAttributes: unknown[]) {
    return this.command<Record>("create", [factory, ...traitsAndAttributes])
  }

  scenario<T = { [name: string]: Record }>(name: string, options: unknown = {}) {
    return this.command<T>(`scenarios/${name}`, options)
  }

  // The text of the latest e-mail sent to the address, or null.
  lastMail(to: string) {
    return this.command<string | null>("last_mail", { to })
  }

  async signInLink(to: string) {
    return (await this.lastMail(to))?.match(/https?:\/\/\S+\/auth\/passwordless\/verify\?token=\S+/)?.[0]
  }
}

type Fixtures = {
  rails: Rails
  scenario: GroupScenario
  signIn: (user: Record) => Promise<void>
}

export const test = base.extend<Fixtures>({
  rails: async({ request }, use) => {
    const rails = new Rails(request)
    await rails.command("clean")
    await use(rails)
  },

  scenario: async({ rails }, use) => {
    await use(await rails.scenario<GroupScenario>("group"))
  },

  // Signs out whoever is signed in, so one test can switch between a teacher and a student. Leaving the page
  // first stops its in-flight requests, whose responses would otherwise restore the old session cookie.
  signIn: async({ page, rails }, use) => {
    await use(async(user) => {
      await page.goto("about:blank")
      await page.context().clearCookies()
      await page.goto(await rails.command<string>("sign_in_path", { "user_id": user.id }))
      await expect(page).toHaveURL(/\/home$/)
    })
  },
})

// Radio buttons and checkboxes in this app are visually hidden under the tiles that label them, so
// Playwright sees the tile as covering the input. Checking the input directly is what a click on the tile does.
export async function choose(input: Locator, checked = true) {
  await input.setChecked(checked, { force: true })
}

// A badge, item or shop offer card, found by its heading.
export function card(page: Page, name: string) {
  return page.getByRole("main").getByRole("article").filter({ has: page.getByRole("heading", { name, exact: true }) })
}

// Uploads a file through a list's "Importuj z CSV" dialog and returns the dialog with the preview or the error.
export async function importCsv(page: Page, file: string) {
  await page.getByRole("link", { name: "Importuj z CSV" }).click()
  const dialog = page.getByRole("dialog")
  await dialog.locator("input[type=file]").setInputFiles(`e2e/fixtures/${file}`)
  await dialog.getByRole("button", { name: "Importuj" }).click()
  return dialog
}

// The group wizard's own file field, not the hidden copies that feed its preview forms.
export function wizardCsvInput(page: Page, resource: string) {
  return page.locator(`input[type=file][name="setup[csv][${resource}]"][data-resource]`)
}
