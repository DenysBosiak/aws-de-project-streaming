resource "aws_redshiftserverless_namespace" "main" {
    namespace_name = "analytics-ns-${var.env}"
    db_name = "ecommerce_dwh"
    admin_username = var.rs_admin_user
    admin_user_password = var.rs_admin_password
}

resource "aws_redshiftserverless_workgroup" "main" {
    namespace_name = aws_redshiftserverless_namespace.main.namespace_name
    workgroup_name = "analytics-wg-${var.env}"
    base_capacity = var.env == "prod" ? 32 : 8
    publicly_accessible = true
    subnet_ids = var.private_subnet_ids
}