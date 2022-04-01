##########################################################
#Shared VPC creating in Networking Account
##########################################################
resource "aws_vpc" "shared-vpc" {
  cidr_block = "10.3.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  enable_classiclink = "false"
  tags = {
      Name = "shared-vpc"
  }

}

################################################################
#Create 6 subnets (2 puplic, 2 private and 2 Attch subnets)
################################################################

# 2 shared-private-subnets
resource "aws_subnet" "shared-priv-sub-1" {
  vpc_id = aws_vpc.shared-vpc.id
  cidr_block = "10.3.0.0/25"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "shared-priv-sub-1"
  }
}

resource "aws_subnet" "shared-priv-sub-2" {
  vpc_id = aws_vpc.shared-vpc.id
  cidr_block = "10.3.0.128/25"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "shared-priv-sub-2"
  }
}


# 2 shared-public-subnets
resource "aws_subnet" "shared-pub-sub-1" {
  vpc_id = aws_vpc.shared-vpc.id
  cidr_block = "10.3.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "shared-pub-sub-1"
  }
}

resource "aws_subnet" "shared-pub-sub-2" {
  vpc_id = aws_vpc.shared-vpc.id
  cidr_block = "10.3.2.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "shared-pub-sub-2"
  }
}


# 2 shared-attach-subnets
resource "aws_subnet" "shared-attach-sub-1" {
  vpc_id = aws_vpc.shared-vpc.id
  cidr_block = "10.3.3.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "shared-attach-sub-1"
  }
}

resource "aws_subnet" "shared-attach-sub-2" {
  vpc_id = aws_vpc.shared-vpc.id
  cidr_block = "10.3.4.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = "true"
  tags = {
    "Name" = "shared-attach-sub-1"
  }
}

####################################################
#Creating route tables for shared-vpc
####################################################


resource "aws_route_table" "shared-vpc-rt" {
  vpc_id = aws_vpc.shared-vpc.id

  route {
    cidr_block = "10.0.0.0/8"
    gateway_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
  }

  tags = {
    Name = "shared-vpc-rt"
  }
}

#############################################################
#Create Internet Gateway and attach it to the shared-vpc
#############################################################

resource "aws_internet_gateway" "igw-shared-vpc" {
  vpc_id = aws_vpc.shared-vpc.id

  tags = {
    Name = "igw-shared-vpc"
  }
}

resource "aws_internet_gateway_attachment" "attach-igw-shared-vpc" {
  internet_gateway_id = aws_internet_gateway.igw-shared-vpc.id
  vpc_id              = aws_vpc.shared-vpc.id
}



##############################################################
#Creating NAT Gateway in puplic subnet 1 in shared-vpc
##############################################################

resource "aws_nat_gateway" "nat-gw-pup-sub-1" {
  subnet_id     = aws_subnet.shared-pub-sub-1.id

  tags = {
    Name = "nat-gw-pup-sub-1"
  }
}
#################################################################
#Create TGW that we go to share with the whole Organisation
#################################################################

resource "aws_ec2_transit_gateway" "shared-tgw" {
  #transit_gateway_name = "shared-tgw"
  auto_accept_shared_attachments = "enable"
  amazon_side_asn = "64550"
  dns_support = "enable"
  vpn_ecmp_support = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  #transit_gateway_cidr_blocks = "10.0.0.0/8"
  tags = {
    "Name" = "shared-tgw"
  }
}

###############################################
#Attachement shared-vpc to the shared-tgw
###############################################
resource "aws_ec2_transit_gateway_vpc_attachment" "shared-vpc-attach" {
  subnet_ids = [ aws_subnet.shared-attach-sub-1.id, aws_subnet.shared-attach-sub-2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.shared-tgw.id
  vpc_id = aws_vpc.shared-vpc.id
}


###################################
#Transit Gateway Route Table
###################################

#Transit Gateway Route Table 
resource "aws_ec2_transit_gateway_route_table" "tgw-rt" {
  
  transit_gateway_id = aws_ec2_transit_gateway.shared-tgw.id
  tags = {
    Name = "tgw-rt"
  }
}

#route table association with all attachements
#################################################################
resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-associations-shared-attach" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared-vpc-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-associations-prod-attach" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod-vpc-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-associations-non-prod-attach" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.non-prod-vpc-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
}


#route table propagation with all attachements
#################################################################
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-propagation-shared-attach" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared-vpc-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-propagation-prod-attach" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod-vpc-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tgw-rt-propagation-nn-prod-attach" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.non-prod-vpc-attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt.id
}


#Add routes to prod transit gateway route table
# resource "aws_ec2_transit_gateway_route" "route-prod-to-tgw" {
#   destination_cidr_block         = "0.0.0.0/0"
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.example.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.example.association_default_route_table_id
# }


#####################################
#Share Transit Gateway with RAM
#####################################

#Share the TGW in AWS Resource Access Manager (RAM), Depending if RAM Sharing with AWS Organizations is enabled!
#Creating a new RAM share
resource "aws_ram_resource_share" "share-tgw-resource" {
  name = "share-tgw-resource"
  allow_external_principals = false

  tags = {
    Name = "TGW Resource Share"
  }
}


#Associating the principal(AWS Organisation) with the RAM share
resource "aws_ram_principal_association" "shared-tgw-principal-association" {
  principal = "arn:aws:organizations::506836426456:organization/o-sd95lh413w"
  resource_share_arn = aws_ram_resource_share.share-tgw-resource.arn
}


#Associating the resource(Transit Gateway) with the RAM share
resource "aws_ram_resource_association" "shared-tgw-resource-association" {
  resource_arn = aws_ec2_transit_gateway.shared-tgw.arn
  resource_share_arn = aws_ram_resource_share.share-tgw-resource.arn
}
