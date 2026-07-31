terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 보안 그룹 설정
resource "aws_security_group" "sre_sg" {
  name        = "sre-project-sg-v4"
  description = "Allow HTTP, SSH and SRE ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "sre_server" {
  ami                         = "ami-0ed11f3863410c386" # Ubuntu 22.04 LTS
  instance_type               = "t3.micro"
  associate_public_ip_address = true                    # 👈 퍼블릭 IP 강제 할당

  vpc_security_group_ids = [aws_security_group.sre_sg.id]

  # 초기 부팅 시 Docker 설치 및 프로젝트 자동 실행 (user_data 개선)
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose git
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              cd /home/ubuntu
              git clone https://github.com/Hoit1210/SRE_project.git
              cd SRE_project
              docker-compose up -d --build
              EOF

  tags = {
    Name = "SRE-monitoring-Server"
  }
}

output "public_ip" {
  value = aws_instance.sre_server.public_ip
}
