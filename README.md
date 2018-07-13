# terraform-very-basic-load-balanced-site

Very basic example of using Terraform with AWS and Ansible to create a static site with Nginx with elastic load balancing

This example uses:
* Terraform for Infrastructure as Code
* Amazon Web Services as the service provider, including the following resources
  * Virtual Private Cloud which contains the other resources
  * Elastic Load Balancer to balance load between the EC2 instances
  * Security Groups to provide web access to the world and SSH access to control IPs
* Ansible for Configuration Management
* Nginx for the simple web server

I also copy in the local .vimrc and .screenrc to all environments, because it's handy to have something familiar when you need to debug.

## Dependencies and Setup

To use this configuration, you will need to install [Terraform](https://www.terraform.io/). Also, the installation assumes a local installation of [Ansible](https://www.ansible.com/). It also assumes that you have an AWS account with a user that has privileges to provision new resources. Once you have done so, you can place the credentials in your local user's account per their instructions. For instance, on a Linux system, you might have a file `~/.aws/credentials` similar to the following:

```
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_KEY
region = "us-east-1"
```

Once these are installed, the next step would be to initiallize the Terraform instance:

```bash
terraform init
```

This will inistialize the `aws` provider.

Next, you will want to create an SSH key and public key pair. On a typical Linux system, you can do so with:

```bash
ssh-keygen -f ssh/control_key
```

Remember the location of the key and the private key for the configuration file.

Copy `local.auto.tfvars.example` to `local.auto.tfvars` and edit it with your key file information, as well as any IP addresses from which you would like to connect to your servers. You can place those values in `control_cidrs`. This is a comma separated list of strings, each of which is a full CIDR. That means that to use a single IP address, you can place `/32` after it, or you could use any CIDR block to specify an IP range. These can be changed later, and would only need to have the changes applied to the terraform insance, as the IPs are assinged through the VPC, making the group mutable.

Finally, when you are ready to test, you can run:

```bash
terraform plan
```

Assuming that this goes well, you can apply your changes to launch the infrastructure:

```bash
terraform apply
```

## Accessing the running instance

Upon success, you should receive a web address for the load balanced access, the path you used for your SSH key, and a list of the IP addresses for the web instances.

If you would like to review this information, you could do so with:

```bash
terraform output
```

Specifically, as an example, to get the key:

```bash
terraform output control_key
```

Here is an example of how you could quickly enter into the first of your web instances from a BASH command line, assuming that you have [jq](https://stedolan.github.io/jq/) installed:

```bash
ssh -i $(terraform output control_key) ec2-user@$(terraform output -json web_ips | jq -r .value[0])
```

## Website content

Currently, the setup only expects static websites. You can find the website content at `ansible/roles/web/files/www/` The whole directory will be copied. Furthermore, the index.html will be generated from a template at `ansible/roles/web/templates/index.html.j2`. This website is the stock website for Nginx on Amazon Linux, except that I have used the template to add an extra header with the local IP address of the running instance.

## Updating Configuration Management

This instance uses the playbooks located in the `ansible/` directory. The `master.yml` playbook assumes that the web instances are listed in an inventory with the group `web`. For this simple example, I am using [terraform-inventory](https://github.com/adammck/terraform-inventory) which uses the terraform state data to compose an inventory. If you download a copy of this script into the 'ansible/` directory, then you should be able to update the servers with a command like:

```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key $(terraform output control_key) -u ec2-user --inventory=./ansible/terraform-inventory ansible/master.yml
```

This should apply any changes you make the the website files, template files, or to the roles themselves.
