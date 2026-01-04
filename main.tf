
# [1] VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.7.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "day7-vpc" }
}

# [2] Subnet
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.7.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags                    = { Name = "day7-public-a" }
}

# [3] igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "day7-igw" }
}

# [4] route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "day7-public-rt" }
}

# [5] assoc
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

# [6] sg-web
resource "aws_security_group" "web_sg" {
  name   = "day7-web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = { Name = "day7-web-sg" }
}

# [7] ec2 instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail

dnf -y update
dnf -y install nginx awscli

# nginx 기본 문서 루트에 작성
cat > /usr/share/nginx/html/index.html <<'HTML'
<html>
  <body>
    <h1>===== S3 LIST START =====</h1>
    <pre>
HTML

aws s3 ls s3://${aws_s3_bucket.bucket.bucket} >> /usr/share/nginx/html/index.html 2>&1 || true
echo "Bucket name: ${aws_s3_bucket.bucket.bucket}" >> /usr/share/nginx/html/index.html
echo "</pre></body></html>" >> /usr/share/nginx/html/index.html

systemctl enable --now nginx
EOF


  tags = { Name = "day7-ec2" }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# [8] S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket        = "day-7-bucket-${random_id.rand.hex}"
  force_destroy = true
  tags          = { Name = "day7-bucket" }
}

resource "random_id" "rand" {
  byte_length = 4
}

# [9] IAM Role & Policy & Instance Profile
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "day7-ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "attach_s3_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "day7-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# [10] output
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}