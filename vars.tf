variable "consulVersion" {
  type    = "string"
  default = "1.4.0"
}

variable "region" {
  type    = "string"
  default = "change or use runtime"
}

variable "projectName" {
  type    = "string"
  default = "change or use runtime"
}

variable "serviceAccount" {
  type = "map"

  default = {
    "email"  = "change or use runtime"
    "scopes" = "change or use runtime"
  }
}

variable "userName" {
  type    = "string"
  default = "change or use runtime"
}

variable "localPath" {
  type    = "string"
  default = "change or use runtime"
}

variable "machineTypes" {
  type = "map"

  default = {
    "consul-server" = "n1-standard-2"
    "nomad-server"  = "n1-standard-8"
    "nomad-client"  = "n1-standard-2"
  }
}

variable "counts" {
  type = "map"

  default = {
    "consul-server" = 3
    "nomad-server"  = 3
    "nomad-client"  = 3
  }
}

variable "imageSpec" {
  type    = "string"
  default = "debian-cloud/debian-9"
}
