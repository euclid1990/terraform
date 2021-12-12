# Terraform Training

## IaC and Its Benefits

![Iac and Its benefit](assets/infrastructure_as_code-and-its-benefit.png)

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

### Setting AWS configuration

```bash
# Configure  AWS  CLI
aws configure
# Disable the pager for a single command use
aws configure set cli_pager ""
# Lists  the  IAM  users
aws iam list-users
# Lists all managed policies that are attached to the specified IAM user
aws iam list-attached-user-policies --user-name {your_aws_user_name}
```

- To create policies that control the access to AWS, use [AWS Policy Generator](https://awspolicygen.s3.amazonaws.com/policygen.html)

### Terraform Providers

- Provider are Terraform's way of **abstracting** integrations with **API control layer** of the infratstructure vendors
- **Terraform Providers registry**\
  <https://registry.terraform.io/browse/providers>
  - Example: [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest), [AWS Provider Document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

- Providers are **plugins**.
- You can write your own custom providers as well.

---

## Naming Conventions

### General conventions

- Use `_` (underscore) instead of `-` (dash) in all: resource names, data source names, variable names, outputs.
- Only use lowercase letters and numbers.

### Resource and data source arguments

- Resource and data source arguments
  - Good: `resource "aws_route_table" "public" {}`
  - Bad: `resource "aws_route_table" "public_route_table" {}`
  - Bad: `resource "aws_route_table" "public_aws_route_table" {}`
- Resource name should be named `this` / `main` if there is no more descriptive and general name available, or if resource module creates single resource of this type (eg, there is single resource of type `aws_nat_gateway` and multiple resources of type `aws_route_table`, so `aws_nat_gateway` should be named `this` / `main` and `aws_route_table` should have more descriptive names - like `private`, `public`, `database`).
- Naming Convention for AWS Resources:\
  `${Product}_${Environment}_${ComponentType}_${ServiceName}_${ServiceComponent}_${ComponentReference}`\
  A Lambda function would then have a Name like the following:\
  - `ProductA_Stag_Lambda_Integration_Requeue_C140`
  - `ProductA_Prod_IAMRole_Integration_C141`
  - `ProductA_Prod_EC2_Web_Master_C142`
- Always use singular nouns for names.
- Use `-` inside arguments values and in places where value will be exposed to a human (eg, inside DNS name of RDS instance).
- [More...](https://www.terraform-best-practices.com/naming)

---

## Key Concept

### Workflow

- `Write → Plan → Apply`

  ![What is the Terraform Workflow](assets/terraform_workflow.png)

  - `Write`: Create code.
  - `Plan`: Review change / Does not deploy. \
  In this state authentication credentials are used to connect your infrastructre if required.
  - `Apply`: Provision real infrastructure.\
  Update the deployment state tracking mechanism file (state file).
  - `Destroy`: Destroys all resources created by code.\
  Non-reversible command. Take backup, and be sure that you want to delete infrastructure.

### State

- Its map real world resource to Terraform configuration
- Resource tracking: A way for Terraform to keep tabs on what has been deployed
- `terraform.tfstate`: A JSON dump containing all the metadata about your Terraform deployment. Stored locally in the same directory where Terraform code resides.
- For better integrity and availability `terraform.tfstate` can also be stored remotely. Allow sharing state between distributed team via AWS S3, GCP Storage.
  - Remote state allows locking so parrallel executions dont coincide

    ![Terrafrom remote state storage](assets/terraform_state-remote_storage.png)
  - Enable sharing "output" values with other Terraform configuration or code

    ![Terrafrom remote output sharing](assets/terraform_state-remote_output.png)
- Because the state file is so critical to Terraform's functionality so:
  - **Never lose it**
  - **Never let it into wrong hands even**
- Scenario use Terraform state command:
  - Advanced state management
  - Manually remove a resource from Terraform State file so that it not managed by Terraform\
    `terraform state rm`
  - Listing out tracked resource\
    `terrform state list`
  - Show the details resources\
    `terraform state show`


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
- 2 types of provisioners (run once)
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

---

## Terraform Modules

### Accessing and Using Terraform Modules

- Terraform module is a container for multiple resources that are used together
  - Make code reusable.
- Directory hold main Terraform code is called the `root` module.
  - If you never work with modules before. Definitely always worked inside the root module.
  - If you invoke other modules inside your code. Newly referenced modules are known as child modules.
- Modules can be downloaded or referenced from
  - Terraform Public/Private/Local Registry
- Module are referenced using `module` block

  ```terraform
  module "my-vpc-module" {
    source  = "./module/vpc"
    version = "0.0.5"
    region  = var.region
  }
  ```

  `module`: Reversed keyword\
  `"my-vpc-module"`: Module name\
  `source`: Module source\
  `version`: Module version\
  `region`: Input parameters
  - Other allowed parameters: `count`, `for_each`, `provider`, `depends_on`

- Module can take optionally take input and provide outputs to pluck back main code.

  ```terraform
  resource "aws_instance" "vpc-module" {
    ... # Other arguments
    subnet_id = module.my-vpc-module.subnet-id
  }
  ```

### Interacting with Terraform Module Inputs and Outputs

