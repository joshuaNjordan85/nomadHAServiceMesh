data "template_file" "nomad-systemd-server" {
  template = "${file("${var.localPath}/configuration/templates/systemd/nomad.tpl")}"

  vars {
    userName = "${var.userName}"
    hclPath  = "server"
  }
}

data "template_file" "nomad-systemd-client" {
  template = "${file("${var.localPath}/configuration/templates/systemd/nomad.tpl")}"

  vars {
    userName = "${var.userName}"
    hclPath  = "client"
  }
}

data "template_file" "consul-systemd-server" {
  template = "${file("${var.localPath}/configuration/templates/systemd/consul-server.tpl")}"

  vars {
    userName = "${var.userName}"
  }
}

data "template_file" "consul-systemd-client" {
  template = "${file("${var.localPath}/configuration/templates/systemd/consul-client.tpl")}"

  vars {
    userName = "${var.userName}"
  }
}

provider "google" {
  credentials = "${file("/Users/jjordan/Hashicorp/.creds/gcp/jjordan-test-a9bf57f5dfdb.json")}"
  project     = "${var.projectName}"
  region      = "${var.region}"
  zone        = "${var.region}-a"
}

#DATA SOURCES
data "google_compute_network" "east" {
  name     = "default" #maybe, but probably change this
  provider = "google"
}

#FIREWALLS: NOMAD & CONSUL (TCP)
resource "google_compute_firewall" "allow-tcp" {
  provider = "google"
  name     = "allow-tcp-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["8300", "8301", "8302", "8500", "4646", "4647"]
  }
}

#FIREWALLS: NOMAD & CONSUL (UDP)
resource "google_compute_firewall" "allow-udp" {
  provider = "google"
  name     = "allow-udp-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "udp"
    ports    = ["8301", "8302", "4648"]
  }
}

#FIREWALLS: HTTP/S ++ :8080
resource "google_compute_firewall" "allow-service-access" {
  provider = "google"
  name     = "http-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
}

#FIREWALLS: SSH
resource "google_compute_firewall" "allow-ssh" {
  provider = "google"
  name     = "ssh-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
