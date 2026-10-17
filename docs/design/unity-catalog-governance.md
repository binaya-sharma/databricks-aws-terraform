# Unity Catalog Governance

## Status

Unity Catalog is a planned phase of this project. This guide records the intended governance model; it does not mean that a metastore, workspace assignment, storage credential, external location, catalog, or permission has been created.

The networking foundation and Databricks workspace must be available before implementing this design. Review the current AWS-specific Databricks documentation before applying it, since product capabilities and configuration details can change.

## What Unity Catalog governs

Unity Catalog (UC) is Databricks' centralized data and AI governance layer. It provides a consistent place to organize data assets, assign ownership, control access, and track usage across assigned workspaces.

The main namespace has three levels:

```text
metastore
└── catalog
    └── schema
        └── table, view, volume, function, or model
```

Catalogs are useful for broad boundaries such as environment, business domain, or data classification. Schemas organize related assets inside a catalog. Grants can be made at different levels and inherited by descendants where the privilege model allows it. Ownership and grants should be designed deliberately rather than relying on broad access at the metastore level.

## AWS storage and identity

UC on AWS uses AWS IAM roles and S3 access policies to let Databricks access approved storage. In Databricks, a **storage credential** represents the AWS identity, and an **external location** pairs that credential with an approved S3 path. Permissions on the external location control which principals can use that path through UC.

Keep these S3 purposes separate in this project:

| S3 purpose | Role |
| --- | --- |
| Terraform state bucket | Stores Terraform state for the infrastructure deployment. It is not a data location. |
| Databricks workspace root bucket | Supports workspace-level storage needs. It is configured as part of workspace provisioning. |
| UC managed storage location | Stores data for UC-managed assets in a controlled S3 location. |
| UC external locations | Expose specifically approved existing S3 paths to UC. |

Use dedicated, narrowly scoped S3 prefixes and IAM permissions for UC. Do not grant broad bucket access simply to make a workspace work. Avoid direct access to UC-managed storage paths outside the governed access path. The exact IAM trust policy and policy actions must be selected from the current Databricks AWS instructions during implementation.

## Planned governance approach

1. **Establish the metastore boundary.** Confirm the Databricks account, AWS region, and workspace eligibility. Create or select the regional metastore and assign the intended workspace.
2. **Prepare storage and AWS access.** Choose a dedicated S3 location for UC managed storage. Create the required IAM role and trust relationship with least privilege, then register it in UC as a storage credential.
3. **Register approved external data.** Create external locations for specific S3 paths using the appropriate storage credential. Grant use of each location only to the groups that need it.
4. **Create the namespace.** Define catalogs for agreed isolation boundaries, then schemas for teams or data areas. Set managed storage deliberately where needed.
5. **Set ownership and access.** Use Databricks groups for people and automation identities. Assign owners and grant only the required privileges at the narrowest practical level.
6. **Add data controls.** Apply descriptions, tags, and classification conventions. Where required and supported by the chosen table format and workload, add row filters or column masks.
7. **Verify governance.** Test access as representative users and groups, confirm workspace-to-catalog bindings where isolation requires them, and review audit and lineage visibility.

## Access design principles

- Prefer group-based grants over grants to individual users.
- Separate development and production data boundaries when production is introduced.
- Give each team or automation principal only the permissions needed for its tasks.
- Keep catalog and schema ownership explicit and assign it to stable groups or service principals.
- Treat external-location access and catalog data privileges as separate controls. A principal may need the relevant permissions at both layers for an operation.
- Use workspace-catalog bindings when a catalog must be available only to selected workspaces.
- Review access regularly and remove grants that are no longer needed.

## Example namespace for discussion

This is an illustrative starting point, not a finalized naming decision:

```text
dev metastore
└── learning
    ├── raw
    ├── curated
    └── analytics
```

For example, the data engineering group might own `learning.raw` and manage ingestion there, while analyst groups receive read access to selected assets in `learning.curated` or `learning.analytics`. Actual groups, catalog names, data classifications, and privileges should be decided before the UC phase is applied.

## Keep the three AWS roles distinct

The AWS role used for Databricks cross-account workspace deployment, the role used by UC storage credentials, and the Terraform execution identity serve different purposes. They should not be combined by default. Their trust relationships and permissions should be reviewed independently and limited to their respective tasks.

## Implementation checklist

- [ ] Confirm the workspace and metastore regions match the intended data placement.
- [ ] Confirm the UC metastore exists and the target workspace is assigned.
- [ ] Select and document the managed-storage S3 path.
- [ ] Create and review the least-privilege IAM role and trust policy.
- [ ] Register and validate the storage credential.
- [ ] Register only required external locations and S3 prefixes.
- [ ] Define catalogs, schemas, owners, and group grants.
- [ ] Configure workspace bindings and data controls where needed.
- [ ] Test allowed and denied access using representative identities.
- [ ] Document audit, lineage, and access review procedures.
