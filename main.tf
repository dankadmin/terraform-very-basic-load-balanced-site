# Specify the AWS Provider and configure the region
provider "aws" {
    region = "${var.aws_region}"
}

# SSH key to access instances
resource "aws_key_pair" "control" {
    key_name_prefix = "terraform_control"
    public_key = "${file("${var.control_public_key_path}")}"
}

# Create a Virtual Private Cloud
resource "aws_vpc" "infrastructure" {
    cidr_block = "${var.cidr_vpc}"
}

# Internet gateway for public access
resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.infrastructure.id}"
}

resource "aws_route" "internet_access" {
    route_table_id         = "${aws_vpc.infrastructure.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = "${aws_internet_gateway.gw.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
    vpc_id                  = "${aws_vpc.infrastructure.id}"
    cidr_block              = "${var.cidr_subnet}"
    map_public_ip_on_launch = true
}

# A security group for web access
resource "aws_security_group" "web_access" {
  name        = "terraform_web_access"
  description = "Provides web access from the internet"
  vpc_id      = "${aws_vpc.infrastructure.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A security group for internal access
resource "aws_security_group" "internal_access" {
  name        = "terraform_internal_access"
  description = "Provides web and SSH access"
  vpc_id      = "${aws_vpc.infrastructure.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.control_cidrs}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance
resource "aws_instance" "web" {
    ami           = "${lookup(var.amis, var.aws_region)}"
    instance_type = "t2.micro"
	key_name = "${aws_key_pair.control.id}"


    count=2

    vpc_security_group_ids = ["${aws_security_group.internal_access.id}","${aws_security_group.web_access.id}"]
    subnet_id = "${aws_subnet.default.id}"

    tags = {
        Name = "web_example-${count.index}"
        Role = "web"
    }

    provisioner "remote-exec" {
        inline = ["sudo yum -y install python"]

        connection {
            type = "ssh"
            user = "ec2-user"
            private_key = "${file("${var.control_key_path}")}"
        }
    }

    provisioner "local-exec" {
        command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user --private-key ${var.control_key_path} -i ${self.public_ip}, ansible/web.yml"
    }
}

# Load balancer
resource "aws_elb" "web" {
    name = "terraform-web-example-elb"

    subnets         = ["${aws_subnet.default.id}"]
    security_groups = ["${aws_security_group.web_access.id}"]
    instances       = ["${aws_instance.web.*.id}"]

    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
}
