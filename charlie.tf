provider "aws" {
  region = "ap-south-1"
  profile = "aws"
}


resource "aws_instance" "webos" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "neokey"
  security_groups = [ "launch-wizard-3" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/vivekPC/Downloads/neokey.pem")
    host     = aws_instance.webos.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "vivekos"
  }

}


resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = aws_instance.webos.availability_zone
  size              = 1
  tags = {
    Name = "vivekvolume"
  }
}


resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs_volume.id}"
  instance_id = "${aws_instance.webos.id}"
  force_detach = true
}


output "myos_ip" {
  value = aws_instance.webos.public_ip
}


resource "null_resource" "nulllocal1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.webos.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "nullremote1"  {

depends_on = [
    aws_volume_attachment.ebs_attach,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/vivekPC/Downloads/neokey.pem")
    host     = aws_instance.webos.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/gitviveks/awsterraform.git /var/www/html/"
    ]
  }
}



resource "null_resource" "nulllocal2"  {


depends_on = [
    null_resource.nullremote1,
  ]

	provisioner "local-exec" {
	    command = "chrome  ${aws_instance.webos.public_ip}"
  	}
}


