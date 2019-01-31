// 3 nomad server instances
resource "google_compute_instance" "nomad-server" {
  depends_on   = ["google_compute_instance.consul-server"]
  count        = "${var.counts["nomad-server"]}"
  name         = "nomad-server-${count.index}"
  machine_type = "${var.machineTypes["nomad-server"]}"
  zone         = "${var.region}-a"
  tags         = ["workshirt-cluster-dc1", "nomad-server", "consul-client", "http-server"]

  metadata {
    sshKeys = "${var.userName}:${file("~/.ssh/id_rsa.pub")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.imageSpec}"
    }
  }

  service_account {
    email  = "${var.serviceAccount["email"]}"
    scopes = "${list(var.serviceAccount["scopes"])}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install unzip",
      "mkdir /home/${var.userName}/nomad.d",
      "mkdir /home/${var.userName}/opt",
      "mkdir /home/${var.userName}/opt/nomad",
      "mkdir /home/${var.userName}/consul.d",
      "mkdir /home/${var.userName}/consul.d/data",
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content = <<HCL
    datacenter = "dc1"
    data_dir = "/home/${var.userName}/opt/nomad"
    server {
      enabled = true
      bootstrap_expect = ${var.counts["nomad-server"]}
    }
    HCL

    destination = "/home/${var.userName}/nomad.d/server.hcl"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    source      = "${var.localPath}/zips/consul_${var.consulVersion}_linux_amd64.zip"
    destination = "/home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    source      = "${var.localPath}/zips/nomad-enterprise_0.8.6+ent_linux_amd64.zip"
    destination = "/home/${var.userName}/nomad-enterprise_0.8.6+ent_linux_amd64.zip"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content = <<JSON
    {
        ${jsonencode("server")}: false,
        ${jsonencode("node_name")}: ${jsonencode("nomad-server-${count.index}")},
        ${jsonencode("datacenter")}: ${jsonencode("dc1")},
        ${jsonencode("data_dir")}: ${jsonencode("/home/${var.userName}/consul.d/data")},
        ${jsonencode("bind_addr")}: ${jsonencode("0.0.0.0")},
        ${jsonencode("client_addr")}: ${jsonencode("0.0.0.0")},
        ${jsonencode("advertise_addr")}: ${jsonencode("${self.network_interface.0.access_config.0.nat_ip}")},
        ${jsonencode("retry_join")}: ${jsonencode("${list("provider=gce project_name=${var.userName}-test tag_value=workshirt-cluster-dc1")}")},
        ${jsonencode("log_level")}: ${jsonencode("DEBUG")},
        ${jsonencode("enable_syslog")}: true,
        ${jsonencode("acl_enforce_version_8")}: false
      }
      JSON

    destination = "/home/${var.userName}/consul.d/client.json"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content     = "${data.template_file.consul-systemd-client.rendered}"
    destination = "/home/${var.userName}/consul-client.service"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content     = "${data.template_file.nomad-systemd-server.rendered}"
    destination = "/home/${var.userName}/nomad.service"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    inline = [
      "unzip /home/${var.userName}/nomad-enterprise_0.8.6+ent_linux_amd64.zip",
      "unzip /home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip",
      "sudo mv /home/${var.userName}/consul /bin/",
      "sudo mv /home/${var.userName}/nomad /bin/",
      "rm /home/${var.userName}/nomad-enterprise_0.8.6+ent_linux_amd64.zip",
      "rm /home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip",
      "sudo mv /home/${var.userName}/*.service /etc/systemd/system/",
      "sudo systemctl start consul-client",
      "sudo systemctl start nomad",
    ]
  }
}
