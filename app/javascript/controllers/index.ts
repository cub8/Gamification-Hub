import { application } from "./application"

import HelloController from "./hello_controller"
import TomSelectController from "./tom_select_controller"

application.register("hello", HelloController)
application.register("tom-select", TomSelectController)
