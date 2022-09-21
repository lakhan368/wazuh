#AWSprovider
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["/home/lakhan/.aws/credentials"]
  profile                  = "default"
}

#ssh key to ec2 instance
resource "aws_key_pair" "lakhan_pem" {
  key_name   = "aws_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4Srh05pkTkNzPoKOpns4LrnqrRuq7cgW6XSNiZu7wJ2/FhpR2mPAOXFizcAOSvX8//2kyV1yb9x7cGrPLbo1q7JKqmGQADtQ2HSWgfw1Iw5W02vFTdJ/DXxU1d63pmLPZdqKya9leejqJaXdORnJIbFLu1fsm0zrPqWY7l8Av8mxdqlbdtFefZTUg+VeD/qDauz1WISZ7PPQaAeJxoyT4jmAE4Cw+olOVHa5FhcxsNRUgYmAMJviQV7Ylkjothid/fnVYYo3MXaou59P/skpItmKjyZveLbFs04ujhrU187vqtyl9W8KoyM/ziVG202ToTPbTI8Cki/Oq7Ox3COmWdhbfVRFyE/gT7W7T8mGBlHL+v45VDnMLRZnpmvh0ODDsXVsx7z9exnBHqRFS7X69sOphlkZgqSSGDWkH35+ItlPRUW5sGjsMjW4c5bS6fSnAAHUFABDD9pKjVP+HM7u7kCylWO9Ye2qKAYUkX/c6HzndAicnNB6wfCVuM6HEhglvJ985Thjw/xa2MTfALWbF7cZCp/j+lH+5jz4WPPOtgsfD7j9eNJ18OWxbK36iyBmFnG//iUQmQc2BBKOPg0t1EHOYa0r7DIWe7fFVT2FrLVJcLJ2Hw9N0JnfVXQkqI65yWFz09/0dx5LB+kQjSuhXHFNXpDiYcKGAleEsB65RKQ== lakhan@w1"
}



data "external" "whatismyip" {
  program = ["/bin/bash", "mypublicip.sh"]
}

#creation of ec2-instance
resource "aws_instance" "wazuh_master" {

  ami                    = "ami-052efd3df9dad4825"
  instance_type          = "t3.medium"
  key_name               = "aws_key"
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data              = <<-EOL
    #!/bin/bash

    sudo su -

    cd /home/ubuntu

    apt-get update && apt-get upgrade -y

    printf  "\n\n*******Docker and Docker-Compose installation started.***********\n\n"

    if which docker
        then
        printf "\n\nDocker already installed...Skipping\n\n"
    else
        #Docker installation process begin
        sudo apt-get remove docker docker-engine docker.io containerd runc -y
        sudo apt-get update
        sudo apt-get install apt-transport-https ca-certificates  curl gnupg-agent software-properties-common -y
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io -y
    fi

    #start and enable docker daemon
    systemctl start docker
    systemctl enable docker
    docker version


    printf  "\n\n********Docker installation Completed********\n\n"
    printf "\n\n********Docker-Compose installation********\n\n"

    if which docker-compose
    then
        printf "\n\n  Docker-compose already installed\n\n"
    else
    curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    fi

    printf  "\n\n*******Docker and Docker-Compose installation completed.***********\n\n"



    printf  "\n\n*******Cloning latest wazuh docker-compose file.***********\n\n"


    git clone https://github.com/wazuh/wazuh-docker.git -b v4.3.7 --depth=1

    sysctl -w vm.max_map_count=262144
    
    cd wazuh-docker/single-node

    docker-compose -f generate-indexer-certs.yml run --rm generator

    docker-compose up -d

    EOL
  tags = {
    Name = "Wazuh-manager"
  }
}


#security-group
resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = [format("%s/%s", data.external.whatismyip.result["internet_ip"], 32)]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 443
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 443
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 1514
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = true
      to_port          = 1514
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 1515
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = true
      to_port          = 1515
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 1516
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = true
      to_port          = 1516
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 514
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "udp"
      security_groups  = []
      self             = true
      to_port          = 514
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 514
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = true
      to_port          = 514
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 9200
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = true
      to_port          = 9200
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 55000
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = true
      to_port          = 55000
    }
  ]
}

#output section
output "wazuh_master" {
  value = aws_instance.wazuh_master.public_ip
}
output "wazuh_master_private_ip" {
  value = aws_instance.wazuh_master.private_ip
}

output "wazuh_master_Security_id" {
  value = aws_security_group.main.id
}




#The default username and password for the Wazuh dashboard are “admin” and SecretPassword. 

#curl -so wazuh-agent-4.3.7.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.3.7-1_amd64.deb && sudo WAZUH_MANAGER='172.31.95.203' WAZUH_AGENT_GROUP='default' dpkg -i ./wazuh-agent-4.3.7.deb

#/var/ossec/bin/agent-auth -m 172.31.95.203<private-ip>

#sed -i '108i \\t<directories check_all="yes" realtime="yes" report_changes="yes">/home/ubuntu/wazuh-agent</directories>' /var/ossec/etc/ossec.conf
#<syscheck><directories check_all="yes" realtime="yes" report_changes="yes">/home/ubuntu/wazuh-agent</directories></syscheck>

#systemctl restart wazuh-agent
#terraform output -json >> wazuh_agent/input.json