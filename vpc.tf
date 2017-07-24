resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "ambari-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

/*
  Public Subnet
*/
resource "aws_subnet" "eu-west-1a-public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.public_subnet_cidr}"
  availability_zone = "eu-west-1a"

  tags {
    Name = "Public Subnet"
  }
}

resource "aws_route_table" "eu-west-1a-public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Public Subnet Gateway"
  }
}


resource "aws_route_table_association" "eu-west-1a-public" {
  subnet_id = "${aws_subnet.eu-west-1a-public.id}"
  route_table_id = "${aws_route_table.eu-west-1a-public.id}"
}

resource "aws_network_acl" "default" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.eu-west-1a-public.id}"]

  ingress {
    from_port = 0
    to_port = 0
    rule_no = 100
    action = "allow"
    protocol = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port = 0
    to_port = 0
    rule_no = 100
    action = "allow"
    protocol = "-1"
    cidr_block = "0.0.0.0/0"
  }

}
resource "aws_security_group" "ambari" {
  name = "vpc_web"
  description = "Allow incoming HTTP connections."



  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      "141.92.0.0/16"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "141.92.0.0/16"]
  }


  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [
      "${aws_vpc.default.cidr_block}"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "Ambari"
  }
}

resource "aws_spot_instance_request" "master" {
  ami = "${lookup(var.amis, var.aws_region)}"
  availability_zone = "eu-west-1a"
  instance_type = "m3.2xlarge"
  spot_price    = "0.15"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.ambari.id}"]
  subnet_id = "${aws_subnet.eu-west-1a-public.id}"
  source_dest_check = false
  associate_public_ip_address = true

  tags {
    Name = "master"
    hdp = "master"
  }
}

resource "aws_spot_instance_request" "slave" {
  ami = "${lookup(var.amis, var.aws_region)}"
  availability_zone = "eu-west-1a"
  instance_type = "m3.large"
  spot_price    = "0.08"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.ambari.id}"]
  subnet_id = "${aws_subnet.eu-west-1a-public.id}"
  associate_public_ip_address = true
  source_dest_check = false
  count = "3"


  tags {
    Name = "slave-${count.index}"
    hdp = "slave"

  }
}

resource "aws_instance" "ansible" {
  ami = "ami-405f7226"
  availability_zone = "eu-west-1a"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.ambari.id}"]
  subnet_id = "${aws_subnet.eu-west-1a-public.id}"
  source_dest_check = false
  associate_public_ip_address = true

  provisioner "file" {
    source = "path/to/ansible"
    destination = "/home/ubuntu/ansible"

    connection {
      agent = false
      user = "ubuntu"
      host = "${self.public_ip}"
      private_key = "${file(var.aws_key_path)}"
      timeout = "2m"
    }
  }

  provisioner "file" {
    source = "${var.aws_key_path}"
    destination = "/home/ubuntu/aws-key.pem"

    connection {
      agent = false
      user = "ubuntu"
      host = "${self.public_ip}"
      private_key = "${file(var.aws_key_path)}"
      timeout = "2m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-add-repository ppa:ansible/ansible -y -u",
      "sudo apt-get install -y ansible python2.7-boto --allow-unauthenticated",

    ]
    connection {
      agent = false
      user = "ubuntu"
      host = "${self.public_ip}"
      private_key = "${file(var.aws_key_path)}"
      timeout = "2m"
    }
  }
}


resource "aws_route53_zone" "bar" {
  name = "ambari.mydomain.suffix"
}




output "ip" {
  value = "${aws_instance.ansible.public_dns}"

}

output "hostname" {
  value = "${aws_instance.ansible.public_ip}"
}

