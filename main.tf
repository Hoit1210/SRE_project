terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # 서울 리전
}

# 보안 그룹 설정 (웹, Grafana, Prometheus 포트 오픈)
resource "aws_security_group" "sre_sg" {
  name        = "sre-project-sg"
  description = "Allow HTTP and SRE ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH 접속
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Web App
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Grafana
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Prometheus
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ubuntu EC2 인스턴스 생성
resource "aws_instance" "sre_server" {
  ami           = "ami-0ed11f3863410c386" # Ubuntu 22.04 LTS (서울 리전 기준)
  instance_type = "t2.micro"             # AWS Free Tier 적용 가능

  security_groups = [aws_security_group.sre_sg.name]

  # EC2 시작 시 Docker 및 Docker Compose 자동 설치
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose git
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "SRE-Monitoring-Server"
  }
}

output "public_ip" {
  value = aws_instance.sre_server.public_ip
}
