output "root_password" {
    description = "Generated password for instance root user"
    value = random_password.root_password.result
    sensitive = true
}
output "backstage_instance_ipv4" {
    description = "Public ipv4 address of Backstage instance"
    value = linode_instance.backstage_instance.ip_address
}
output "backstage_fqdn" {
  description = "Domain for Backstage HTTPS access"
  value = "https://${var.backstage_subdomain}.${var.backstage_domain}"
}
