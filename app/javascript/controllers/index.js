// Import and register all controllers from the controllers directory

import { application } from "controllers/application"

// Eager load all controllers defined in the controllers directory
import DashboardController from "controllers/dashboard_controller"
import FlashController from "controllers/flash_controller"
import MonitorController from "controllers/monitor_controller"
import MonitorFormController from "controllers/monitor_form_controller"
import ResponseChartController from "controllers/response_chart_controller"

application.register("dashboard", DashboardController)
application.register("flash", FlashController)
application.register("monitor", MonitorController)
application.register("monitor-form", MonitorFormController)
application.register("response-chart", ResponseChartController)
