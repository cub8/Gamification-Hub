import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

type OptionData = {
  id?: number | string
  name?: string
  email?: string
  value?: string
  text?: string
}

// Connects to data-controller="tom-select"
class TomSelectController extends Controller {
  private select?: TomSelect

  connect() {
    const el = this.element as HTMLElement

    const options: OptionData[] = JSON.parse(
      el.dataset.tomSelectOptionsValue || "[]",
    )

    this.select = new TomSelect(this.element as HTMLSelectElement, {
      options,
      create: false,
      maxItems: 1,

      valueField: "value",
      labelField: "text",

      searchField: ["name", "email", "id"],

      sortField: [
        {
          field: "name",
          direction: "asc",
        },
      ],

      render: {
        option: this.renderOption,
        item: this.renderItem,
      },
    })
  }

  disconnect() {
    this.select?.destroy()
  }

  private renderOption = (
    data: OptionData,
    escape: (input: string) => string,
  ): string => {
    return `
      <div>
        <strong>${escape(data.name || "")}</strong><br>
        <small style="color: #888;">
          ${escape(data.email || "")} (Index: ${escape(String(data.id ?? ""))})
        </small>
      </div>
    `
  }

  private renderItem = (
    data: OptionData,
    escape: (input: string) => string,
  ): string => {
    return `
      <div>
        <strong>${escape(data.name || "")}</strong>
        <small style="color: #888;">
          &nbsp; ${escape(data.email || "")}
        </small>
      </div>
    `
  }
}

application.register("tom-select", TomSelectController)
