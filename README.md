# Manually Deploy a Backstage Developer Portal on Akamai

Deploy Backstage, an open developer portal, on Akamai using Opentofu and Ansible. A developer portal like Backstage can help organization in centralizing and managing internal tools, services, and documentation. 

## Before Starting

This deployment uses [OpenTofu](link) which must be installed locally. It also requires a Linode API token. 
The app deploys with a SSL secured Nginx reverse proxy, and Github Authentication. You will need a [registered domain](link) using the [Linode nameservers](link).

Before deployment you will need to create a new OAuth App in Github to link with Backstage.
```
- Add a new app to GitHub
Go to https://github.com/settings/applications/new to create your OAuth App.

- Homepage URL should point to Backstage's frontend. This is the DNS record that will be created
 http://$FQDN

- Authorization callback URL should point to the auth backend
 http://localhost:7007/api/auth/github/handler/frame

Generate a new `Client Secret` and take a note of the `Client ID` and the `Client Secret`.
```
# Deploying Backstage
1. Clone this repo locally, and open [variables.tf]. Take note of the values, and update where necessary. Variables without a default will need to be entered from the command line.

2. From the repo root run `tofu init`. When this process completes you can run `tofu plan -out tofu_out.plan` this generates a small binary you can use to run ` tofu apply "tofu_out.plan"` which will deploy the infastructure. 