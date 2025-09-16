variable "instance_type" {
    type = string
    description = "This is the Instance Type"
}

variable "key_filename" {
    type = string
    description = "This is the pem key file to access the EC2 instance"
}

variable "key_path" {
    type = string
    description = "This is the path of the pem key file"
}