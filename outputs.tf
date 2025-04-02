output "info" {
  value = {
    client_ip = "ssh -i ./ssh_private ubuntu@${aws_instance.ubuntu.public_ip}"
  }
}