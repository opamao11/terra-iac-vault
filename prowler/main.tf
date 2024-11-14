# IAM Role for Prowler Instance
resource "aws_iam_role" "prowler_role" {
  name = "ProwlerInstanceRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

# Attach AdministratorAccess Policy to the Role
resource "aws_iam_role_policy_attachment" "prowler_attach_admin_policy" {
  role       = aws_iam_role.prowler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM Instance Profile for EC2 to assume the Role
resource "aws_iam_instance_profile" "prowler_instance_profile" {
  name = "ProwlerInstanceProfile"
  role = aws_iam_role.prowler_role.name
}

# EC2 Instance for Prowler Setup
resource "aws_instance" "prowler_setup" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_groups      = [var.security_group_id]
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.prowler_instance_profile.name
  tags = {
    Name = "Prowler Setup Instance"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Updating system packages'",
      "sudo apt update -y",
      "echo 'Installing dependencies'",
      "sudo apt install -y git python3-pip python3-venv python3-dev python3-full",

      "echo 'Checking for existing prowler directory'",
      "if [ ! -d 'prowler' ]; then git clone https://github.com/prowler-cloud/prowler.git; fi",
      "cd prowler",
      "python3 -m venv venv",

      "echo 'Installing Python dependencies'",
      "venv/bin/pip install packaging alive-progress schema tabulate slack_sdk boto3 tzlocal kubernetes colorama jsonschema pytz",
      "venv/bin/pip install pydantic==1.10.18 detect-secrets cryptography==43.0.1 py-ocsf-models",

      "echo 'Setting permissions for prowler.py'",
      "chmod +x prowler.py",

      "echo 'Running Prowler for report generation'",
      "venv/bin/python prowler.py -M json-asff > /home/ubuntu/prowler_report.json",
      "venv/bin/python prowler.py -M html > /home/ubuntu/prowler_report.html"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
      timeout     = "15m"  # Increased timeout for longer installations
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Output the Public IP of the Instance
output "instance_public_ip" {
  value = aws_instance.prowler_setup.public_ip
}
