output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}
output "vpc_id" {
  value = aws_vpc.terraform_vpc.id
}
