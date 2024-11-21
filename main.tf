terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.27.0" }
    template = {
      source = "opentofu/template"
      version = "2.2.0" }
  }
}
# Configure Linode provider
provider "linode" {
  token = var.linode_token
}
data "linode_profile" "me" {
}
data "linode_domains" "current_dns" {
  filter {
    name = "domain"
    values = ["${var.backstage_domain}"]
  }
}
resource "random_password" "root_password" {
  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
# random_password.root_password.result
# set instance variables
resource "linode_domain" "backstage_domain" {
  count = var.create_dns_zone == true ? 1 : 0
  type = "master"
  domain = "${var.backstage_domain}"
  soa_email = "${var.soa_email}"
}
# Create cloudinit-config
data "template_file" "backstage_config_template" {
  template = "${file("${path.module}/backstage-cloud-config.tftpl")}"
  vars = {
    app_name = "${var.app_name}"
    root_password = "${local.root_password}"
    sudo_username = "${var.sudo_username}"
    backstage_domain = "${var.backstage_domain}"
    backstage_subdomain = "${var.backstage_subdomain}"
    soa_email = "${var.soa_email}"
    github_oauth_client_id = "${var.github_oauth_client_id}"
    github_oauth_client_secret = "${var.github_oauth_client_secret}"
    github_username = "${var.github_username}"
  }
}
data "template_cloudinit_config" "backstage_cloud_config" {
  gzip          = false
  base64_encode = true
  part {
    filename     = "cloud-init.yml"
    content_type = "text/cloud-config"
    content = data.template_file.backstage_config_template.rendered
  }
}
# Create Backstage node
resource "linode_instance" "backstage_instance" {
  image = "linode/ubuntu22.04"
        label = "${var.app_name}_instance"
        region = var.region
        type = var.backstage_instance_type
        authorized_users = [data.linode_profile.me.username]
        root_pass = "${local.root_password}"
  metadata {
    user_data = data.template_cloudinit_config.backstage_cloud_config.rendered
  }
  interface {
    purpose = "public"
  }
}
resource "linode_domain_record" "backstage_subdomain" { 
  record_type = "A"
  target = "${local.backstage_ip}"
  name = "${var.backstage_subdomain}"
  domain_id = data.linode_domains.current_dns.domains.0.id != "" ? data.linode_domains.current_dns.domains.0.id : linode_domain.backstage_domain.0.id 
}
resource "linode_firewall" "backstage_firewall" {
  label = "${var.app_name}_firewall"
  inbound_policy = "DROP"
  outbound_policy = "DROP"

  inbound {
    label = "backstage_web_gui"
    action = "ACCEPT"
    protocol = "TCP"
    ports = "80,443"
    ipv4 = ["0.0.0.0/0"]
  }
  inbound {
    label = "backstage_backend"
    action = "ACCEPT"
    protocol = "TCP"
    ports = "3000,7007,22"
    ipv4 = [var.workstation_ipv4 != "" ? var.workstation_ipv4 : "0.0.0.0/0"]
  }
  linodes = [linode_instance.backstage_instance.id]
}
locals {
  backstage_ip = linode_instance.backstage_instance.ip_address
  root_password = random_password.root_password.result
  backstage_id = linode_instance.backstage_instance.id
}