// Import and register all Stimulus controllers

import { application } from "./application"

import HelloController from "./hello_controller"
import DropdownController from "./dropdown_controller"
import FlashController from "./flash_controller"
import UploadController from "./upload_controller"
import ScanStatusController from "./scan_status_controller"
import FileUploadController from "./file_upload_controller"
import TabsController from "./tabs_controller"
import PasswordVisibilityController from "./password_visibility_controller"
import ChartController from "./chart_controller"
import VulnerabilityChartController from "./vulnerability_chart_controller"
import DependencyTreeController from "./dependency_tree_controller"
import ModalController from "./modal_controller"
import PolicyFormController from "./policy_form_controller"

application.register("hello", HelloController)
application.register("dropdown", DropdownController)
application.register("flash", FlashController)
application.register("upload", UploadController)
application.register("scan-status", ScanStatusController)
application.register("file-upload", FileUploadController)
application.register("tabs", TabsController)
application.register("password-visibility", PasswordVisibilityController)
application.register("chart", ChartController)
application.register("vulnerability-chart", VulnerabilityChartController)
application.register("dependency-tree", DependencyTreeController)
application.register("modal", ModalController)
application.register("policy-form", PolicyFormController)
