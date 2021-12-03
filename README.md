# Terraform Training

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
  `"web"`: User-provided arbitary resource name\
  `ami = "ami-a1b2c3d4"`: Resource config parameter

- Resource Address

  `aws_instance.web`: Resource address

- Data Resource Block

  ```terraform
  data "aws_instance" "my-vm" {
    instance_id = "i-1234567890abcdef0"
  }
  ```
