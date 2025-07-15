# ============================================================================
# DATA SOURCES
# ============================================================================
# Data sources gather information about existing AWS resources
# Used to make the module flexible across different regions and configurations
# ============================================================================

# Available Availability Zones
# Retrieves all available AZs in the current region
# Used to distribute subnets across multiple AZs for high availability
data "aws_availability_zones" "available" {
  state = "available"
  
  # Filter out AZs that might not support all instance types
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# ============================================================================
# VPC CORE RESOURCES
# ============================================================================
# The VPC is the foundation of AWS networking, providing an isolated
# virtual network environment. All other resources are deployed within this VPC.
# ============================================================================

# Virtual Private Cloud (VPC)
# Creates an isolated virtual network within AWS
# Provides complete control over networking environment including IP addressing,
# subnets, route tables, and network gateways
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true  # Required for ELB and other services
  enable_dns_support   = true  # Enables DNS resolution within VPC
  
  # Instance tenancy - default allows shared hardware
  # Can be changed to 'dedicated' for compliance requirements
  instance_tenancy = "default"

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-vpc"
    Purpose   = "Main VPC for ${var.name_prefix} infrastructure"
    ManagedBy = "terraform"
    Module    = "vpc"
  })
}

# Internet Gateway
# Provides internet access for resources in public subnets
# Acts as a gateway between the VPC and the internet
# Required for any resources that need direct internet connectivity
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-igw"
    Purpose   = "Internet gateway for ${var.name_prefix} VPC"
    ManagedBy = "terraform"
    Module    = "vpc"
  })
}

# ============================================================================
# SUBNET RESOURCES
# ============================================================================
# Subnets divide the VPC into smaller network segments across AZs
# Public subnets have direct internet access, private subnets use NAT
# Multi-AZ deployment ensures high availability and fault tolerance
# ============================================================================

# Public Subnets
# Subnets with direct internet access via Internet Gateway
# Used for load balancers, bastion hosts, and other internet-facing resources
# Auto-assigns public IPs to instances launched in these subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  # Auto-assign public IPs

  tags = merge(var.tags, {
    Name                     = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type                     = "Public"
    AvailabilityZone        = data.aws_availability_zones.available.names[count.index]
    Purpose                 = "Public subnet for internet-facing resources"
    ManagedBy               = "terraform"
    Module                  = "vpc"
    # Kubernetes tags for EKS integration
    "kubernetes.io/role/elb" = "1"
  })
}

# Private Subnets
# Subnets without direct internet access, use NAT Gateway for outbound traffic
# Used for application servers, databases, and other internal resources
# Provides additional security by isolating resources from direct internet access
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type                              = "Private"
    AvailabilityZone                 = data.aws_availability_zones.available.names[count.index]
    Purpose                          = "Private subnet for internal resources"
    ManagedBy                        = "terraform"
    Module                           = "vpc"
    # Kubernetes tags for EKS integration
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# ============================================================================
# NAT GATEWAY RESOURCES
# ============================================================================
# NAT Gateways provide outbound internet access for private subnets
# Each AZ gets its own NAT Gateway for high availability
# Elastic IPs provide static public IP addresses for the NAT Gateways
# ============================================================================

# Elastic IP Addresses for NAT Gateways
# Static public IP addresses required for NAT Gateways
# One EIP per NAT Gateway to ensure consistent outbound IP addresses
# Useful for whitelisting in external services and security groups
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"  # VPC-scoped EIP (not EC2-Classic)
  
  # Ensure Internet Gateway exists before creating EIPs
  depends_on = [aws_internet_gateway.this]

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-nat-eip-${count.index + 1}"
    Purpose   = "Elastic IP for NAT Gateway in AZ ${data.aws_availability_zones.available.names[count.index]}"
    ManagedBy = "terraform"
    Module    = "vpc"
  })
}

# NAT Gateways
# Managed NAT service for outbound internet access from private subnets
# Deployed in public subnets to provide internet access for private resources
# Highly available within each AZ, multiple NAT Gateways provide cross-AZ redundancy
resource "aws_nat_gateway" "this" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name             = "${var.name_prefix}-nat-gw-${count.index + 1}"
    AvailabilityZone = data.aws_availability_zones.available.names[count.index]
    Purpose          = "NAT Gateway for private subnet outbound traffic"
    ManagedBy        = "terraform"
    Module           = "vpc"
  })

  # Ensure Internet Gateway is created first
  depends_on = [aws_internet_gateway.this]
}

# ============================================================================
# ROUTING RESOURCES
# ============================================================================
# Route tables control traffic flow within the VPC and to external networks
# Public route tables direct traffic to Internet Gateway
# Private route tables direct traffic to NAT Gateways for outbound access
# ============================================================================

# Public Route Table
# Routes traffic from public subnets to the Internet Gateway
# Single route table shared by all public subnets for simplicity
# All internet-bound traffic (0.0.0.0/0) goes through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  # Default route to Internet Gateway for internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-public-rt"
    Type      = "Public"
    Purpose   = "Route table for public subnets with internet access"
    ManagedBy = "terraform"
    Module    = "vpc"
  })
}

# Private Route Tables
# One route table per private subnet for AZ-specific NAT Gateway routing
# Each private subnet routes through its AZ's NAT Gateway for outbound traffic
# Provides fault isolation - if one NAT Gateway fails, others continue working
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  # Default route to NAT Gateway for internet access
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(var.tags, {
    Name             = "${var.name_prefix}-private-rt-${count.index + 1}"
    Type             = "Private"
    AvailabilityZone = data.aws_availability_zones.available.names[count.index]
    Purpose          = "Route table for private subnet ${count.index + 1}"
    ManagedBy        = "terraform"
    Module           = "vpc"
  })
}

# ============================================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================================
# Associates subnets with their respective route tables
# Determines which route table controls traffic for each subnet
# ============================================================================

# Public Subnet Route Table Associations
# Associates all public subnets with the single public route table
# All public subnets share the same routing behavior (direct internet access)
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnet Route Table Associations
# Associates each private subnet with its corresponding private route table
# Each private subnet uses its AZ-specific NAT Gateway for outbound traffic
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ============================================================================
# SECURITY GROUP RESOURCES
# ============================================================================
# Default security group provides basic network access rules
# Acts as a starting point for common access patterns
# Can be referenced by other modules for consistent security policies
# ============================================================================

# Default Security Group
# Provides common ingress rules for HTTP, HTTPS, and SSH access
# Allows all outbound traffic for maximum flexibility
# Can be used as a base security group for common services
resource "aws_security_group" "default" {
  name_prefix = "${var.name_prefix}-default-sg-"
  vpc_id      = aws_vpc.this.id
  description = "Default security group for ${var.name_prefix} VPC with common access rules"

  # HTTP Access (Port 80)
  # Allows inbound HTTP traffic from specified IP ranges
  # Commonly used for web applications and load balancers
  ingress {
    description = "HTTP access from allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # HTTPS Access (Port 443)
  # Allows inbound HTTPS traffic from specified IP ranges
  # Essential for secure web applications and APIs
  ingress {
    description = "HTTPS access from allowed IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # SSH Access (Port 22)
  # Allows inbound SSH traffic from specified IP ranges
  # Used for server administration and management
  # Should be restricted to known IP addresses in production
  ingress {
    description = "SSH access from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # All Outbound Traffic
  # Allows all outbound traffic to any destination
  # Provides maximum flexibility for applications
  # Can be restricted based on security requirements
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-default-sg"
    Purpose   = "Default security group with common access rules"
    ManagedBy = "terraform"
    Module    = "vpc"
  })

  # Lifecycle management to prevent issues during updates
  lifecycle {
    create_before_destroy = true
  }
}