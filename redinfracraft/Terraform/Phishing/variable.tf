variable "key_name" {
    
}


variable "security_group" {
  description = "Security group for EC2 Instance creatted through Terraform."
  default = "Terra_Phish_Ec2_sg"
}
