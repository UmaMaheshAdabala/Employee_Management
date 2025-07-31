variable "my-public-subnet" {
  type = object({
    availability_zone = list(string),
    cidr_block        = list(string),
    name              = list(string)

  })
  description = "Public subnet Arguments"

  default = {
    availability_zone = ["ap-south-1a", "ap-south-1b"],
    cidr_block        = ["10.0.1.0/24", "10.0.2.0/24"],
    name              = ["my-public-subnet-1a", "my-public-subnet-1b"]
  }
}


variable "my-private-subnet" {
  type = object({
    availability_zone = list(string),
    cidr_block        = list(string),
    name              = list(string)
  })
  description = "Private Subnet Arguments"

  default = {
    availability_zone = ["ap-south-1a", "ap-south-1b", "ap-south-1c"],
    cidr_block        = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"],
    name              = ["my-private-subnet-1a-rds", "my-private-subnet-1b", "my-private-subnet-1c-rds"]
  }
}

variable "db-username" {
  type      = string
  sensitive = true
  default   = "admin"
}

variable "db-password" {
  type      = string
  sensitive = true
  default   = "12345678"
}
