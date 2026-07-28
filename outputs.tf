output "vpc_id" {
  value = aws_vpc.dr_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet1_id" {
  value = aws_subnet.private1.id
}

output "private_subnet2_id" {
  value = aws_subnet.private2.id
}

output "security_group_id" {
  value = aws_security_group.terraform_sg.id
}
