variable "allow_ports" {
  type = map(string)
  default = {
    "22" = "10.0.0.0/16"
    "80" = "10.0.1.0/24"
  }
}

resource "aws_security_group" "veera-sg" {
    name = "veera-sg"
    
dynamic "ingress" {
  for_each = var.allow_ports
  content {
    description = "allow"
    from_port = ingress.key
    to_port = ingress.key
    protocol = "tcp"
    cidr_blocks = [ingress.value]
  }
}
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}