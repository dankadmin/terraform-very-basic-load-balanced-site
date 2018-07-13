variable "aws_region" {
    description = "AWS region to launch instance. Available regions: us-east-1"
    default = "us-east-1"
}

variable "control_public_key_path" {
    description = "Location of a public key for an associated private key you will be using for accessing instances."
}

variable "control_key_path" {
    description = "Location of a private key for an associated public key you will be using for accessing instances."
}

variable "amis" {
    type = "map"
    default = {
        "us-east-1" = "ami-e965ba80"
    }
}

variable "control_cidrs" {
    description = "List of CIDR blocks which should have controll access."
    type = "list"
} 

variable "cidr_vpc" {
    description = "CIDR block for the VPC instance."
    default = "10.2.0.0/16"
}

variable "cidr_subnet" {
    description = "CIDR block for the public facing subnet."
    default = "10.2.1.0/24"
}

