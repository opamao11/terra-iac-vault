resource "aws_instance" "vault_setup" {
  ami           = var.ami_id                   # AMI ID passed from variables.tf
  instance_type = var.instance_type            # Instance type from variables.tf
  key_name      = var.key_name                 # Key pair for SSH access from variables.tf

  subnet_id              = var.subnet_id            # Subnet ID from variables.tf
  vpc_security_group_ids = [var.security_group_id]  # Security group ID from variables.tf

  user_data = <<-EOF
    #!/bin/bash
    # Step 1 - Update and install gpg
    sudo apt update && sudo apt install -y gpg

    # Step 2 - Add the HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Step 3 - Verify the key's fingerprint
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

    # Step 4 - Add the official HashiCorp Linux repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Step 5 - Update and install Vault
    sudo apt update && sudo apt install -y vault

    # Step 6 - Create required directories and set permissions
    sudo mkdir -p /etc/vault.d /opt/vault/data
    sudo chown -R vault:vault /etc/vault.d /opt/vault/data
    sudo chmod -R 750 /etc/vault.d /opt/vault/data

    # Step 7 - Create the Vault configuration file with mlock disabled and properly formatted
    cat <<EOT | sudo tee /etc/vault.d/vault.hcl
    disable_mlock = true

    storage "file" {
      path = "/opt/vault/data"
    }

    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = "true"
    }
    EOT

    # Step 8 - Create the Vault environment file
    echo 'VAULT_ADDR="http://127.0.0.1:8200"' | sudo tee /etc/vault.d/vault.env

    # Step 9 - Update the Vault systemd service file with the correct ExecStart and disable memory locking
    sudo sed -i 's|ExecStart=/usr/bin/vault server.*|ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl|' /usr/lib/systemd/system/vault.service
    sudo sed -i 's|CapabilityBoundingSet=.*|#CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK|' /usr/lib/systemd/system/vault.service
    sudo sed -i 's|LimitMEMLOCK=.*|#LimitMEMLOCK=infinity|' /usr/lib/systemd/system/vault.service

    # Step 10 - Reload systemd, enable, and start Vault
    sudo systemctl daemon-reload
    sudo systemctl enable vault
    sudo systemctl start vault

    # Step 11 - Output Vault logs for troubleshooting
    sudo journalctl -u vault.service -b >> /var/log/vault_startup.log
  EOF

  tags = {
    Name = "VaultSetupInstance"
  }
}

output "instance_ip" {
  value       = aws_instance.vault_setup.public_ip
  description = "The public IP address of the Vault setup instance."
}
