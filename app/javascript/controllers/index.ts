import "@controllers/hello_controller"
import "@controllers/sortable_form_controller"
import "@controllers/nested_rondo_controller"
import "@controllers/template_loader_controller"
import "@controllers/activity_group_name_dialog_controller"
import "@controllers/bulk_create_dialog_controller"

import { application } from "./application"

import TomSelectController from "./tom_select_controller"
application.register("tom-select", TomSelectController)
