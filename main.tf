# Create Security Group to allow inbound ports for SSH and Jenkins
resource "aws_security_group" "jenkins_server_sg" {
    name = "jenkins-server-sg"
    description = "Security Group for the EC2 instance"

    ingress {
        description = "To allow port 22"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "To allow port 8080"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "To allow outbound traffic"
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Data Block to lookup an Ubuntu AMI
data "aws_ami" "my_ami" {
    most_recent = true
    owners = ["099720109477"]
    
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}

data "aws_iam_role" "aws_secret_jenkins_role" {
    name = "JenkinsEC2SecretsRole"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
    name = "jenkins-instance-profile"
    role = data.aws_iam_role.aws_secret_jenkins_role.name 
}

# Resource Block to create an EC2 instance
resource "aws_instance" "my_server" {
    ami = data.aws_ami.my_ami.id
    instance_type = var.instance_type
    key_name = var.key_filename
    vpc_security_group_ids = [aws_security_group.my_server_sg.id]
    iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name 

    provisioner "remote-exec" {
        inline = [
            "set -xe",                       # Show and fail fast on errors
            "sleep 30",                      # Let cloud-init finish on EC2

            # Clean up and fix any broken configs
            "sudo apt-get update -y",
            "sudo apt-get install -f -y",
            "sudo dpkg --configure -a",

            # Base updates and dependencies
            "sudo apt-get install -y gnupg curl unzip software-properties-common lsb-release",

            # Install OpenJDK (for Jenkins)
            "sudo apt-get install -y openjdk-21-jdk",
            "java -version",

            # Install Jenkins
            "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
            "echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
            "sudo apt-get update -y",
            "sudo apt-get install -y jenkins",
            "sudo systemctl daemon-reexec",
            "sudo systemctl enable jenkins",
            "sudo systemctl start jenkins",

            # Install AWS CLI
            "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
            "unzip awscliv2.zip",
            "sudo ./aws/install",
            "aws --version"
        ]
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file(var.key_path)
        host = self.public_ip
    }

    tags = {
        Name = "jenkins-server"
    }
}