import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

type OptionData = {
  university_number?: number | string
  name?: string
  email?: string
  value?: string
  text?: string
}

type EscapeCallback = (input: string) => string

class TomSelectUserController extends Controller {
  private select?: TomSelect

  connect() {
    const el = this.element as HTMLElement

    const options: OptionData[] = JSON.parse(
      el.dataset.tomSelectOptionsValue || "[]",
    )

    this.select = new TomSelect(this.element as HTMLSelectElement, {
      options,
      plugins: ["clear_button"],
      create: false,
      maxItems: 1,
      valueField: "value",
      labelField: "text",
      searchField: ["name", "email", "university_number"],
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

  private renderOption(data: OptionData, escape: EscapeCallback) {
    const idPart = data.university_number != null ?
      ` (Index: ${escape(String(data.university_number))})` :
      ""

    return `
      <div>
        <strong>${escape(data.name || "")}</strong><br>
        <small style="color: #888;">
          ${escape(data.email || "")}${idPart}
        </small>
      </div>
    `
  }

  private renderItem(data: OptionData, escape: EscapeCallback) {
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

application.register("tom-select-user", TomSelectUserController)
