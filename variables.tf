variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
  default  = "vpc-0ce28592841b7d15b"
}


variable "subnets" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = ["subnet-0dd68c5ed1ba79cae", "subnet-008e7570bae13c08f"]
}


variable "ami_id" {
  description = "The ID of the AMI"
  type        = string
  default  = "ami-0927306d7ce0cd574"
}
