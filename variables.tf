variable "linode_token" {
  description = "Linode APIv4 Personal Access Token"
  sensitive = true
}
variable "workstation_ipv4" {
  description = "Incoming ipv4 address for instance access; must be valid CIDR"
}
variable "backstage_domain" {
  description = "Domain zone for Backstage access. Must be configured to Linode nameservers."
}
variable "create_dns_zone" {
  description = "Create a new zone for top level domain?"
  type = bool  
}
variable "backstage_subdomain" {
  description = "Subdomain name for Backstage access"
}
variable "soa_email" {
  description = "Email address for Backstage domain."  
}
variable "github_username" {
  description = "Github Username to auth with. Must be be linked to OAuth App" 
  type = string 
}
variable "github_oauth_client_id" {
  description = "Github OAuth Client ID"
  sensitive = true
}
variable "github_oauth_client_secret" {
  description = "Github OAuth Client Secret"
  sensitive = true
}
variable "sudo_username" {
  description = "Name for generated sudo user"
  type = string
}
variable "region" {
  description = "The region to deploy the Linode Instances in."
  default = "us-mia"
}
variable "app_name" {
  description = "Name for Backstage application and install directory"
  default = "backstage"
  type = string
}
variable "backstage_instance_type" {
  description = "Linode Instance type to use for Backstage front-end node."
  default = "g6-standard-2"
  type = string
}

