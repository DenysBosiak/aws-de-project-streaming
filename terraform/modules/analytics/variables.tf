variable "env"                { default = "dev" }
variable "rs_admin_user"      { default = "admin" }
variable "rs_admin_password"  { sensitive = true }
variable "private_subnet_ids" { type = list(string) }
variable "vpc_id"             {}