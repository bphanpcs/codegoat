#IAM Role
resource "aws_iam_role" "ebilling-ec2-role" {
  name = "ebilling-ec2-role-${var.ebillingid}"
  assume_role_policy = <<EOF
{
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
}
EOF
  tags = {
      Name = "ebilling-ec2-role-${var.ebillingid}"
      Stack = "${var.stack-name}"
      Scenario = "${var.scenario-name}"
  }
}

#Iam Role Policy
resource "aws_iam_policy" "ebilling-ec2-role-policy" {
  name = "ebilling-ec2-role-policy-${var.ebillingid}"
  description = "ebilling-ec2-role-policy-${var.ebillingid}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
              "s3:*",
              "cloudwatch:*",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "iam:PassRole",
              "iam:ListAttachedUserPolicies",
              "iam:GetRole",
              "iam:GetRolePolicy",
              "ec2:DescribeInstances",
              "ec2:CreateKeyPair",
              "ec2:RunInstances",
              "ec2:TerminateInstances",
              "iam:ListRoles",
              "iam:ListInstanceProfiles",
              "iam:ListAttachedRolePolicies",
              "iam:GetPolicyVersion",
              "iam:GetPolicy",
              "ec2:AssociateIamInstanceProfile"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:ListProvisionedConcurrencyConfigs",
                "lambda:ListFunctionEventInvokeConfigs",
                "lambda:ListFunctions",
                "lambda:ListFunctionsByCodeSigningConfig",
                "lambda:InvokeFunction",
                "lambda:ListVersionsByFunction",
                "lambda:ListAliases",
                "lambda:ListEventSourceMappings",
                "lambda:ListFunctionUrlConfigs",
                "lambda:ListLayerVersions",
                "lambda:ListLayers",
                "lambda:ListCodeSigningConfigs"
            ],
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSecurityGroupRules",
            "ec2:DescribeTags"
          ],
          "Resource": "*"
        },
        {
      "Effect": "Allow",
      "Action": [
         "ec2:AuthorizeSecurityGroupIngress", 
         "ec2:RevokeSecurityGroupIngress", 
         "ec2:AuthorizeSecurityGroupEgress", 
         "ec2:RevokeSecurityGroupEgress", 
         "ec2:ModifySecurityGroupRules",
         "ec2:UpdateSecurityGroupRuleDescriptionsIngress", 
         "ec2:UpdateSecurityGroupRuleDescriptionsEgress"
      ],
      "Resource": "*"
     },   
     {
      "Effect": "Allow",
      "Action": [
         "ec2:ModifySecurityGroupRules"
      ],
      "Resource": "*"
     }
    ]
}
POLICY
}

#IAM Role Policy Attachment
resource "aws_iam_policy_attachment" "ebilling-ec2-role-policy-attachment" {
  name = "ebilling-ec2-role-policy-attachment-${var.ebillingid}"
  roles = [
      "${aws_iam_role.ebilling-ec2-role.name}"
  ]
  policy_arn = "${aws_iam_policy.ebilling-ec2-role-policy.arn}"
}

#IAM Instance Profile
resource "aws_iam_instance_profile" "ebilling-ec2-instance-profile" {
  name = "ebilling-ec2-instance-profile-${var.ebillingid}"
  role = "${aws_iam_role.ebilling-ec2-role.name}"
}

#AWS Key Pair
resource "aws_key_pair" "ebilling-ec2-key-pair" {
  key_name = "ebilling-ec2-key-pair-${var.ebillingid}"
  public_key = "${file(var.ssh-public-key-for-ec2)}"
}

#EC2 Instance
resource "aws_instance" "ebilling-ubuntu-ec2" {
    ami = "ami-0155217cad89957e0"
    instance_type = "t2.micro"
    iam_instance_profile = "${aws_iam_instance_profile.ebilling-ec2-instance-profile.name}"
    subnet_id = "${aws_subnet.ebilling-public-subnet-1.id}"
    associate_public_ip_address = true
    private_ip = "10.10.10.103"
    vpc_security_group_ids = [
        "${aws_security_group.ebilling-ec2-ssh-security-group.id}",
        "${aws_security_group.ebilling-ec2-http-security-group.id}"
    ]
    key_name = "${aws_key_pair.ebilling-ec2-key-pair.key_name}"
    root_block_device {
        volume_type = "gp2"
        volume_size = 60
        delete_on_termination = true
    }
    provisioner "file" {
      source = "../app"
      destination = "/home/ubuntu/app"
      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.ssh-private-key-for-ec2)}"
        host = self.public_ip
      }
    }

    provisioner "file" {
      source = "scripts/script.sh"
      destination = "/home/ubuntu/script.sh"
      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.ssh-private-key-for-ec2)}"
        host = self.public_ip
      }
    }

    provisioner "file" {
      source = "scripts/initial_setup.sh"
      destination = "/home/ubuntu/initial_setup.sh"
      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.ssh-private-key-for-ec2)}"
        host = self.public_ip
      }
    }

    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/ubuntu/initial_setup.sh",
        "chmod +x /home/ubuntu/script.sh",
        "/home/ubuntu/initial_setup.sh",
        "/home/ubuntu/script.sh",
      ]
      connection {
          type = "ssh"
          user = "ubuntu"
          private_key = "${file(var.ssh-private-key-for-ec2)}"
          host = self.public_ip
      }
    }
    tags = {
        Name = "ebilling-ubuntu-ec2-${var.ebillingid}"
        Stack = "${var.stack-name}"
        Scenario = "${var.scenario-name}"
    }
}

output "ebilling-ec2-public-ip" {
  value = aws_instance.ebilling-ubuntu-ec2.public_ip
}

output "ebilling-instance-id" {
  value = aws_instance.ebilling-ubuntu-ec2.id
}

output "ebilling-ec2-key-pair" {
  value = aws_key_pair.ebilling-ec2-key-pair.key_name
}
