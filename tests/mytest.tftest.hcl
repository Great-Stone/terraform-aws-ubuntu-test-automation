run "my_ubunut_module_test" {
  command = apply

  variables {
    instance_type = "t3.micro"
  }

  assert {
    condition = aws_instance.ubuntu.id != ""
    error_message = "Instance ID should not be empty"
  }
}