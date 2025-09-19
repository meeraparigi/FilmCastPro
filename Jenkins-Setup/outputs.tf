output "myami" {
    description = "This is my ami id : "
    value = data.aws_ami.my_ami.id
}

output "publicip" {
    description = "The public ip of my EC2 instance is : "
    value = aws_instance.my_server.public_ip
}