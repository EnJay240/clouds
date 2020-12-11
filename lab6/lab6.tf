provider aws {
    access_key = "***"
    secret_key = "***"
    region = "us-east-2"
}


resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "MyKeyPair"
  public_key = tls_private_key.example.public_key_openssh
}


data "aws_ami" "amazon_test" {
  most_recent = true
  owners = ["self"]
}

resource "aws_security_group" "SG"{

    name = "ELB_SG"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
   }

     egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
       Name = "ELB_SG"
   }
}

resource "aws_lb" "ELB" {
    name = "ELB"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.SG.id]
    subnets = ["subnet-c84f46b2", "subnet-2f6a1b63"]

}

resource "aws_instance" "ec2" {
    ami = data.aws_ami.amazon_test.id
    key_name = aws_key_pair.generated_key.key_name
    count = 2
    security_groups = [aws_security_group.SG.name] 
    instance_type = "t2.micro"
    user_data = file(format("user_data%d.sh", count.index))
 
    tags = {
    Name = format("Instance-%d", count.index)
  }
}



resource "aws_lb_target_group" "target_group" {
  name     = "Lab6-Target-Group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-806fc7eb"
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count = length(aws_instance.ec2)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_instance.ec2[count.index].id
  port = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.ELB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}