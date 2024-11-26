# Manually Deploy a Backstage Developer Portal on Akamai

[Backstage Reference Architecture](images/backstage_ref.png)

Backstage is a popular and flexible open-source developer portal, created by Spotify and donated to the CNCF. A developer portal can make it simpler for organizations to manage the many APIs, services and assets of a modern cloud computing workload. This Akamai Cloud Computing deployment uses OpenTofu to manage the state of cloud resources and Ansible for service configuration. When launching the deployment users have options for a managed PostgreSQL cluster, or a database cluster self hosted on Linode Instances. 

## Prerequisites

This deployment uses [OpenTofu](https://opentofu.org/docs/intro/install/) which must be installed locally.
A Linode API token is required to create cloud resources. Follow [Getting started with Linode API](https://techdocs.akamai.com/linode-api/reference/get-started#get-an-access-token) to generate a token. 
It is suggested to [add an SSH Key](link) to your Linode user before provisioning resources.
The app deploys with a SSL secured Nginx reverse proxy pointed to a subdomain. Follow [Getting started with DNS Manager](https://techdocs.akamai.com/cloud-computing/docs/getting-started-with-dns-manager) to point your registered domain to the Linode nameservers. 

### Github Authentication

This deployment includes optional SSO authentication through Github. In order to use Github Authentication, complete the following prerequistes.

On a new or existing Github Account, you need to register an OAuth Application by following these steps. 
```
- Add a new app to GitHub
Go to https://github.com/settings/applications/new to create your OAuth App.

- The Homepage URL should point to Backstage's frontend. This is the DNS record that will be created. It is suggested to use a subdomain A record rather than an `@` record for the top-level domain.
 http://$FQDN

- Authorization callback URL should point to the auth backend
 http://localhost:7007/api/auth/github/handler/frame
```
Generate a new `Client Secret` and take a note of the `Client ID` and the `Client Secret`.

You will provide the `Client ID`, `Client Secret`, and the Github username linked to the OAuth application when using `tofu plan`. 

If you do provide the credentials for Github authentication, a random password will be generated and used for Backstage access.

# Deploying Backstage
1. Begin by cloning this repo locally, and navigating into the module's root directory, `backstage-solution/` in your terminal. This directory contains the OpenTofu and Ansible files defining the state of the application. 

2. From that directory, run the command `tofu init` to load and necessary providers:
    ```
    user@example:~/backstage-solution# tofu init

    Initializing the backend...

    Initializing provider plugins...
    - Finding opentofu/template versions matching "2.2.0"...
    - Finding latest version of hashicorp/random...
    - Finding linode/linode versions matching "2.31.1"...
    - Installing opentofu/template v2.2.0...
    - Installed opentofu/template v2.2.0 (signed, key ID 0C0AF313E5FD9F80)
    - Installing hashicorp/random v3.6.3...
    - Installed hashicorp/random v3.6.3 (signed, key ID 0C0AF313E5FD9F80)
    - Installing linode/linode v2.31.1...
    - Installed linode/linode v2.31.1. Signature validation was skipped due to the registry not containing GPG keys for this provider

    Providers are signed by their developers.
    If you'd like to know more about provider signing, you can read about it here:
    https://opentofu.org/docs/cli/plugins/signing/

    OpenTofu has created a lock file .terraform.lock.hcl to record the provider
    selections it made above. Include this file in your version control repository
    so that OpenTofu can guarantee to make the same selections by default when
    you run "tofu init" in the future.

    OpenTofu has been successfully initialized!

    You may now begin working with OpenTofu. Try running "tofu plan" to see
    any changes that are required for your infrastructure. All OpenTofu commands
    should now work.

    If you ever set or change modules or backend configuration for OpenTofu,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
    ```

3. To input variables for the plan, you can add them directly to the [variables.tf file](variables.tf), pass them through the command-line or as environment variables. 
    - The values marked as `default` in `variables.tf` will not confirm on the inital `tofu plan`. For example, the variable for compute instance plan does not confirm on the command line:
    ```
    variable "backstage_instance_type" {
    description = "Linode Instance type to use for Backstage front-end node."
    default = "g6-standard-2"
    type = string
    }
    ```
    Use the same syntax when adding a default for your deployment:
    ```
    variable "linode_token" {
    description = "Linode APIv4 Personal Access Token"
    sensitive = true
    default = "YOUR_ACTUAL_API_TOKEN"
    }
    ```
    - Running `tofu plan` from the root of the module will open an interactive command line for you to input all the values from `variables.tf` without a `default`.
    ```
    user@example:~/backstage-poc# tofu plan
    
    var.backstage_domain
    Domain zone for Backstage access. Must be configured to Linode nameservers.

    Enter a value:
    ```
    - Values for variables can be provided to the module as environment variables with the prefix `TF_VAR_`. It is important to use the same string listed in `variables.tf` when exporting an environment variable.
    ```
    export TF_VAR_linode_token=YOUR_ACTUAL_API_TOKEN
    ```
    You can refer to the [OpenTofu Documentation](https://opentofu.org/docs/language/values/variables/) on input variables, and [Linode provider documentation](https://github.com/linode/terraform-provider-linode/blob/dev/docs/index.md) for more details on configuring default values for cloud resources. 
    
    **To use Github authentication the domain information provided for deployment must match the details on the Github OAuth App.**

4. With the input variables set or decided, you can run the command `tofu plan -out backstage.plan`. This will return an output listing what changes are necessary to meet the state defined in [main.tf](main.tf), and generate a binary file with the name provided to the command. The plan results may look like:
    ```
    Plan: 4 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
  + backstage_fqdn          = "https://backstage.example.com"
  + backstage_instance_ipv4 = (known after apply)
  + root_password           = (sensitive value)

    ────────────────────────────────────────────────────────────────────────────────    

    Saved the plan to: backstage.plan

    To perform exactly these actions, run the following command to apply:
    tofu apply "backstage.plan"
    ```

5. Running `tofu apply "backstage.plan"` will create the necessary resources on your Linode account. Once the compute instance is running, cloud-init will pull and run the Ansible [backstage.yml](backstage.yml) playbook to complete the installation and setup of Backstage. This may take up to ten minutes. 

6. To access your Backstage instance, navigate to the subdomain you entered on deployment and select `Guest`. 
- If you entered the credentials for Github Authentication, you will be redirected to log in to Github. Only the username provided during deployment will allow access.
- If you chose not to enable Github authentication, a password for Backstage authentication will be generated. Sensitive outputs, like passwords, can be viewed with `tofu output $VAR_NAME`.

The Backstage compute instance is also accessiable via SSH. If you have an SSH key assigned to your Linode user, that key will be copied to the sudo user you entered during deployment. If you do not have an SSH key assigned, you can use the `root_password` generated by OpenTofu. Additional secrets such as database and sudo user passwords are in the file `/home/$SUDO_USERNAME/.credentials`. 

7. If you need to remove the deployment, you can run `tofu destroy` or `tofu plan -destroy -out backstage.destroy`. Note that all resources defined in the state file will be permenantly deleted. 
