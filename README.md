# Terraform Training

## Install Terraform and Terraform Provider

### Install Terraform

#### OS X

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew update
brew upgrade hashicorp/tap/terraform
```

#### Ubuntu Linux

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### Verify the installation

```bash
terraform -help
```

### Terraform Providers

- Provider are Terraform's way of **abstracting** integrations with **API control layer** of the infratstructure vendors
- **Terraform Providers registry**\
  <https://registry.terraform.io/browse/providers>
  - Example: [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest), [AWS Provider Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

- Providers are **plugins**.
- You can write your own custom providers as well.

## Key Concept

### Workflow

- `Write → Plan → Apply`
  - `Write`: Create code.
  - `Plan`: Review change / Does not deploy. \
  In this state authentication credentials are used to connect your infrastructre if required.
  - `Apply`: Provision real infrastructure.\
  Update the deployment state tracking mechanism file (state file).
  - `Destroy`: Destroys all resources created by code.\
  Non-reversible command. Take backup, and be sure that you want to delete infrastructure.

### State

- Resource tracking: A way for Terraform to keep tabs on what has been deployed
- `terraform.tfstate`: A JSON dump containing all the metadata about your Terraform deployment. Stored locally in the same directory where Terraform code resides.
- For better integrity and availability `terraform.tfstate` can also be stored remotely.
- Because the state file is so critical to Terraform's functionality so:
  - **Never lose it**
  - **Never let it into wrong hands even**

### Resource Addressing

- Configuring the Provider

  ```terraform
  provider "aws" {
    region = "us-east-1"

  }

  provider "google" {
    credentials = file("credentials.json")
    project     = "my-gcp-project"
    region      = "us-west-1"
  }
  ```

  `provider`: Reversed keyword\
  `"aws"`: Provider name\
  `region = "us-east-1"`: Configuration parameters\
  `file`: Built-in function

- Resource Block

  ```terraform
  resource "aws_instance" "web" {
    ami           = "ami-a1b2c3d4"
    instance_type = "t2.micro"
  }
  ```

  `resource`: Reserved keyword\
  `"aws_instance"`: Resource provided by the Terraform provider\
  `"web"`: User-provided arbitrary resource name\
  `ami = "ami-a1b2c3d4"`: Resource config parameter

- Data Resource Block

  ```terraform
  data "aws_instance" "my-vm" {
    instance_id = "i-1234567890abcdef0"
  }
  ```

  Each provider may offer data sources alongside its set of resource types.\
  `data`: Reversed keyword\
  `"aws_instance"`: Resource provided by Terraform provider\
  `"my-vm"`: User-provided arbitrary resource name\
  `instance_id = "i-1234567890abcdef0"`

- Resource Address

  `aws_instance.web`: Resource address\
  `data.aws_instance.my-vm"`: my-vm

### Variables and Outputs

- Variables

  ```terraform
  variable "my-var" {
    description = "My Test Variable"
    type        = string
    default     = "Hello"
    sensitive   = false
  }
  ```

  `variable`: Reversed keyword\
  `"my-var"`: User-provided variable name\
  `description/type/default/sensitive`: Variable config arguments\
  Referencing a variable: `var.my-var`

- Validation Feature (Optional)

  ```terraform
  variable "my-var" {
    description = "My Test Variable"
    type        = string
    default     = "Hello"
    validation {
      condition     = length(var.my-var) > 4
      error_message = "The string must be more than 4 characters"
    }
  }
  ```

- Types
  - Basic Types:
    - string
    - number
    - bool
  - Complex Types:
    - list, set, map, object tuple

      ```terraform
      variable "availibility_zone_names" {
        type        = list(string)
        default     = ["us-west-1a"]
      }
      variable "docker_ports" {
        type    = list(object({
          internal = number
          external = number
          protocol = string
        }))
        default = [
          {
            internal = 8080
            external = 8081
            protocol = "tcp"
          }
        ]
      }
      ```

- Output

  ```terraform
  output "instance_ip" {
    description = "VM's Private IP"
    value = aws_instance.my-vm.private_ip
  }
  ```

  `output`: Reversed keyword\
  `"instance_ip"`: User-provided variable name\
  Output variable values are shown on the shell after running `terraform apply`

### Terraform Provisioners

- Terraform way of bootstrap custom scripts, commands or actions
- Can be run either locally or remotely on resource spun up through Terraform deployment
- Each individual resource can have its own "provisioner" defining the connection method (SSH/WinRM) and the actions/commands or scripts to excute
- 2 types of provisioners
  - Creation-time
  - Destroy-time

#### Best Practices and Cautions

- HashiCorp recommends to use them sparingly, and only when the underlying vendors, such as AWS does not already provide a built in mechanism for bootstrapping via custom commands or scripts.
  - For example: AWS allows for passing scripts through user data in EC2 virtual machines. So if there's a better inherently available method for a resource, Hashicorp recommends using that.
- An important thing to note is that, since provisioners can take any independent action through a script or command. Terraform cannot and does not track them, as they break Terraform's declarative model.
- If the command within a provisioner return non-zero code, it's considered failed and underlying resource is tainted.
  - Marks the resource against which the provisioner was to be run to be created again on the next run.

  ```terraform
  resource "null_resource" "dummy_resource" {
    provisioner "local-exec" {
      command = "echo '0' > status.txt"
    }
    provisioner "local-exec" {
      when    = destroy
      command = "echo '1' > status.txt"
    }
  }
  ```

- By default, the provisioner is a create provisioner.
- `terraform apply --auto-approve`
- Variable usage behavior inside provisioner\
  `self.id = aws_instance.ec2-virtual-machine.id`

  ```terraform
  resource "aws_instance" "ec2-virtual-machine" {
    ami = ami-12345
    instance_type = t2.micro
    key_name = aws_key_pair.master-key.key_name
    ...
    provisioner "local-exec" {
      command = "aws ec2 wait instance-status-ok --region us-east-1 --instance-ids ${self.id}"
    }
  }
  ```
