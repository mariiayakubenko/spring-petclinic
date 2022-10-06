#EC2 instances for jenkins and environments

#Use latest ubuntu ami
data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


#Security group
resource "aws_security_group" "security_group_fp" {
  name        = "${var.project}_security_group"
  description = "Security group for ${var.project}"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}_security_group"
  }
}


#IAM role for EC2 to get ssh keys from parameter store
data "aws_iam_policy_document" "policy_document_fp" {
  statement {
    # sid = "1"

    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${var.account_id}:parameter*"
    ]
  }
}

resource "aws_iam_policy" "policy_fp" {
  name   = "${var.project}_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.policy_document_fp.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role_fp" {
  name               = "${var.project}_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    tag-key = "${var.project}_role"
  }
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.role_fp.name
  policy_arn = aws_iam_policy.policy_fp.arn
}


resource "aws_iam_instance_profile" "profile_fp" {
  name = "${var.project}_profile"
  role = aws_iam_role.role_fp.name
}

#Elastic ips
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  vpc      = true
  tags = {
    Name = "${var.project}_jenkins"
  }
}

resource "aws_eip" "jenkins_slave" {
  instance = aws_instance.jenkins_slave.id
  vpc      = true
  tags = {
    Name = "${var.project}_jenkins_slave"
  }
}

resource "aws_eip" "qa" {
  instance = aws_instance.qa.id
  vpc      = true
  tags = {
    Name = "${var.project}_qa"
  }
}

resource "aws_eip" "ci" {
  instance = aws_instance.ci.id
  vpc      = true
  tags = {
    Name = "${var.project}_ci"
  }
}

#EC2 instances
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.latest_ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.profile_fp.name
  vpc_security_group_ids      = [aws_security_group.security_group_fp.id]
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
export AWS_DEFAULT_REGION=${var.region}
export HOST=jenkins
sudo su
apt-get update
apt install awscli -y
aws ssm get-parameter --name $${HOST}_key --query Parameter.Value --output text --query Parameter.Value > /home/ubuntu/.ssh/$${HOST}_key
chmod 600 /home/ubuntu/.ssh/$${HOST}_key
ssh-keygen -f /home/ubuntu/.ssh/$${HOST}_key -y >/home/ubuntu/.ssh/authorized_keys

EOF

  tags = {
    Name = "jenkins_${var.project}"
  }
}

resource "aws_instance" "jenkins_slave" {
  ami                         = data.aws_ami.latest_ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.profile_fp.name
  vpc_security_group_ids      = [aws_security_group.security_group_fp.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/bash
export AWS_DEFAULT_REGION=${var.region}
export HOST=jenkins_slave
sudo su
apt-get update
apt install awscli -y
aws ssm get-parameter --name $${HOST}_key --query Parameter.Value --output text --query Parameter.Value > /home/ubuntu/.ssh/$${HOST}_key
chmod 600 /home/ubuntu/.ssh/$${HOST}_key
ssh-keygen -f /home/ubuntu/.ssh/$${HOST}_key -y >/home/ubuntu/.ssh/authorized_keys

EOF

  tags = {
    Name = "jenkins_slave_${var.project}"
  }
}

resource "aws_instance" "qa" {
  ami                         = data.aws_ami.latest_ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.profile_fp.name
  vpc_security_group_ids      = [aws_security_group.security_group_fp.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/bash
export AWS_DEFAULT_REGION=${var.region}
export HOST=qa
sudo su
apt-get update
apt install awscli -y
aws ssm get-parameter --name $${HOST}_key --query Parameter.Value --output text --query Parameter.Value > /home/ubuntu/.ssh/$${HOST}_key
chmod 600 /home/ubuntu/.ssh/$${HOST}_key
ssh-keygen -f /home/ubuntu/.ssh/$${HOST}_key -y >/home/ubuntu/.ssh/authorized_keys

EOF

  tags = {
    Name = "qa_${var.project}"
  }
}


resource "aws_instance" "ci" {
  ami                         = data.aws_ami.latest_ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.profile_fp.name
  vpc_security_group_ids      = [aws_security_group.security_group_fp.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/bash
export AWS_DEFAULT_REGION=${var.region}
export HOST=ci
sudo su
apt-get update
apt install awscli -y
aws ssm get-parameter --name $${HOST}_key --query Parameter.Value --output text --query Parameter.Value > /home/ubuntu/.ssh/$${HOST}_key
chmod 600 /home/ubuntu/.ssh/$${HOST}_key
ssh-keygen -f /home/ubuntu/.ssh/$${HOST}_key -y >/home/ubuntu/.ssh/authorized_keys

EOF

  tags = {
    Name = "ci_${var.project}"
  }
}


#Associate eip with EC2
resource "aws_eip_association" "eip_assoc_jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}

resource "aws_eip_association" "eip_assoc_jenkins_slave" {
  instance_id   = aws_instance.jenkins_slave.id
  allocation_id = aws_eip.jenkins_slave.id
}

resource "aws_eip_association" "eip_assoc_qa" {
  instance_id   = aws_instance.qa.id
  allocation_id = aws_eip.qa.id
}

resource "aws_eip_association" "eip_assoc_ci" {
  instance_id   = aws_instance.ci.id
  allocation_id = aws_eip.ci.id
}
