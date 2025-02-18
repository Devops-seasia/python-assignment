resource "aws_security_group" "sg1" {
  name        = "golang-server"
  description = "Port 3000"
  vpc_id      = aws_vpc.ecs-vpc.id

  ingress {
    description      = "Allow Port 5000"
    from_port        = 80
    to_port          = 81
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}