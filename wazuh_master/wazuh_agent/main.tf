#AWSprovider
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["/home/lakhan/.aws/credentials"]
  profile                  = "default"
}

#Reading  data from json file
locals {
    # get json 
    user_data = jsondecode(file("${path.module}/input.json"))

    # get all users
    #all_users = [for user in local.user_data.users : user.user_name]
}

#Creation of ec2-instance
resource "aws_instance" "wazuh_agent" {
   count = 2

  ami                    = "ami-052efd3df9dad4825"
  instance_type          = "t2.micro"
  key_name               = "aws_key"
  user_data              = <<-EOL
    #!/bin/bash
    sudo su -
    cd /home/ubuntu
    mkdir wazuh-agent
    cd wazuh-agent
    touch lark
    
    apt-get update && apt-get upgrade -y
    curl -so wazuh-agent-4.3.7.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.3.7-1_amd64.deb && sudo WAZUH_MANAGER=172.31.12.53 WAZUH_AGENT_GROUP='default' dpkg -i ./wazuh-agent-4.3.7.deb
    /var/ossec/bin/agent-auth -m 172.31.12.53
    sed -i '108i\\t<directories check_all="yes" realtime="yes" report_changes="yes">/home/ubuntu/wazuh-agent</directories>' /var/ossec/etc/ossec.conf
    sleep 30
    systemctl restart wazuh-agent
    sleep 30
    rm lark
    EOL
  vpc_security_group_ids = ["sg-08964e44145042d6b"]
  tags = {
    Name = "Wazuh-agent.${count.index}"
  }


}









