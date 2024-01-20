variable "ami_id" {
  description = "The ID of the AMI"
  type        = string
  default  = "ami-0927306d7ce0cd574"
}

variable "instance_type" {
  description = "Type of the Instance"
  type        = string
  default  = "t2.micro"
}
