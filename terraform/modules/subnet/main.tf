resource "aws_subnet" "primary" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_primary
  availability_zone = "${var.region}a"
  tags = {
    git_commit           = "411b42499d3f07561c66b3f588388177f125a6f9"
    git_file             = "terraform/modules/subnet/main.tf"
    git_last_modified_at = "2022-12-06 15:16:54"
    git_last_modified_by = "mroberts@paloaltonetworks.com"
    git_modifiers        = "mroberts"
    git_org              = "bphanpcs"
    git_repo             = "codegoat"
    yor_trace            = "de17a83e-d2cf-41c2-833f-c959687ccca6"
  }
}

resource "aws_subnet" "secondary" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_secondary
  availability_zone = "${var.region}c"
  tags = {
    git_commit           = "411b42499d3f07561c66b3f588388177f125a6f9"
    git_file             = "terraform/modules/subnet/main.tf"
    git_last_modified_at = "2022-12-06 15:16:54"
    git_last_modified_by = "mroberts@paloaltonetworks.com"
    git_modifiers        = "mroberts"
    git_org              = "bphanpcs"
    git_repo             = "codegoat"
    yor_trace            = "7c0c6cf6-3882-483b-937c-801545bb27f0"
  }
}
