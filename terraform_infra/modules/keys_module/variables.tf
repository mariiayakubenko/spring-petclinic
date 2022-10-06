variable "hosts" {
  description = "List of ec2 instances"
  type        = list(any)
  default = [
    "jenkins",
    "jenkins_slave",
    "qa",
    "ci"
  ]
}
