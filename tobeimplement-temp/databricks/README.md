# Deferred Databricks Terraform modules

These modules are retained for the future Databricks integration phase. They are intentionally outside `infrastructure/modules`, so the active dev root cannot load them by accident.

Modules:

- `modules/iam`: AWS cross-account role and Databricks credential registration.
- `modules/storage`: workspace root S3 bucket and Databricks storage registration.
- `modules/databricks-workspace`: Databricks network registration and workspace creation.

They are not connected to the active root, and have not been validated as part of the current networking-only phase. Before reactivation, review current provider versions and Databricks requirements, restore them under `infrastructure/modules`, reconnect inputs and outputs, and inspect the complete Terraform plan.
