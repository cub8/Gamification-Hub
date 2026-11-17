import { defineConfig, devices } from "@playwright/test"

const port = Number(process.env.E2E_PORT ?? 5017)

export default defineConfig({
  testDir: "e2e/tests",
  outputDir: "tmp/playwright/results",
  // Tests share one database and every test truncates it first, so they must not run at the same time.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ?
    [["github"], ["html", { outputFolder: "tmp/playwright/report", open: "never" }]] :
    "list",
  use: {
    baseURL: `http://127.0.0.1:${port}`,
    locale: "pl-PL",
    timezoneId: "Europe/Warsaw",
    trace: "retain-on-failure",
    actionTimeout: 10_000,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  ],
  webServer: {
    // CYPRESS=1 mounts the cypress-on-rails endpoint (see config/initializers/cypress_on_rails.rb).
    command: `bin/rails server -e test -b 127.0.0.1 -p ${port} -P tmp/pids/e2e.pid`,
    env: { CYPRESS: "1" },
    url: `http://127.0.0.1:${port}/up`,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
})
