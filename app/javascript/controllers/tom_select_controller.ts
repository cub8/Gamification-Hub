import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Connects to data-controller="tom-select"
export default class extends Controller {
  private select?: TomSelect

  connect() { 
    console.log("TomSelect Connected")

    const options = JSON.parse(
      this.element.dataset.tomSelectOptionsValue || "[]"
    )

    this.select = new TomSelect(this.element as HTMLSelectElement, {
      options: options,
      create: false,
      maxItems: 1,

      valueField: "value",
      labelField: "text",

      searchField: ["name", "email", "id"],

      sortField: {
        field: "name",
        direction: "asc"
      },

      render: {
        option: (data, escape) => {
          return `
            <div>
              <strong>${escape(data.name || "")}</strong><br>
              <small style="color: #888;">
                ${escape(data.email || "")} (USOS ID: ${escape(String(data.id))})
              </small>
            </div>
          `
        },
        item: (data, escape) => {
          return `
            <div>
              <strong>${escape(data.name || "")}</strong>
              <small style="color: #888;">
                ${escape(data.email || "")}
              </small>
            </div>
          `
        }
      }    
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}
