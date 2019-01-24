#IF YOU WANTED TO USE A PROVISIONER TO DOWNLOAD AFTER SPIN UP
variable "consulVersion" {
  type    = "string"
  default = "1.4.0"
}

variable "projectName" {
  type = "string"
  default = "change me"
}

provider "google" {
  credentials = "${file("/path/to/your/jwt.json")}"
  project     = "${var.projectName}"
  region      = "us-east4"
  zone        = "us-east4-a"
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
   name = "ssh-east"
   network = "${data.google_compute_network.east.self_link}"

   allow {
     protocol = "tcp"
     ports = ["22"]
   }
 }

resource "google_compute_instance" "nomad_server" {
  count        = 3
  name         = "nomad-server-${count.index}"
  machine_type = "n1-standard-8"
  zone         = "${data.google.region}-a"
  tags         = ["nomad-server", "webinar", "consul-client", "http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "consul-server" {
  count        = 3
  name         = "consul-server-${count.index}"
  machine_type = "n1-standard-2"
  zone         = "${data.google.region}-a"
  tags         = ["consul-server", "webinar", "http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}

resource "google_compute_instance" "nomad_client" {
  count        = 3
  name         = "nomad-client-${count.index}"
  machine_type = "n1-standard-2"
  zone         = "${data.google.region}-a"
  tags         = ["nomad-client", "webinar", "consul-client", "http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
}
