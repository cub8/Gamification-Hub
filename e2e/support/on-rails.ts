import { test as base, expect, type APIRequestContext, type Locator } from "@playwright/test"

export { expect }

export type Record = { id: number; [attribute: string]: unknown }
type FactoryCall = [method: "create" | "create_list" | "build", factory: string, ...args: unknown[]]

// Talks to the test server through cypress-on-rails: e2e/app_commands/<name>.rb.
export class Rails {
  constructor(private readonly request: APIRequestContext) {}

  async command<T = unknown>(name: string, options: unknown = {}): Promise<T> {
    const response = await this.request.post("/__e2e__/command", { data: { name, options } })
    expect(response.ok(), await response.text()).toBeTruthy()

    const [result] = await response.json()
    return result
  }

  // Each call maps to FactoryBot, e.g. ["create", "user", "teacher", { email: "a@b.pl" }].
  factories<T = Record>(calls: FactoryCall[]) {
    return this.command<T[]>("factory_bot", calls)
  }

  async create<T = Record>(factory: string, ...traitsAndAttributes: unknown[]) {
    const [record] = await this.factories<T>([["create", factory, ...traitsAndAttributes]])
    return record
  }

  // Runs a scenario from e2e/app_commands/scenarios and returns what it builds.
  scenario<T = { [name: string]: Record }>(name: string, options: unknown = {}) {
    return this.command<T>(`scenarios/${name}`, options)
  }
}

type Fixtures = {
  rails: Rails
  signIn: (user: Record) => Promise<void>
}

export const test = base.extend<Fixtures>({
  rails: async({ request }, use) => {
    const rails = new Rails(request)
    await rails.command("clean")
    await use(rails)
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
