variable "project" { type = string }
variable "exoscale_api_key" { type = string }
variable "exoscale_api_secret" { type = string }
variable "exoscale_pgsql_user" { type = string }
variable "exoscale_pgsql_pwd" { type = string }
variable "exoscale_zone" { type = string }
variable "exoscale_priv_reg_user" { type = string }
variable "exoscale_priv_reg_pwd" { type = string }

locals {
  zone = var.exoscale_zone
}

terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
    }
  }
}


provider "exoscale" {
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}

resource "exoscale_security_group" "sks" {
  name = "${var.project}-sks"
}

resource "exoscale_security_group_rules" "sks" {
  security_group = exoscale_security_group.sks.name

  ingress {
    description              = "Calico traffic"
    protocol                 = "UDP"
    ports                    = ["4789"]
    user_security_group_list = [exoscale_security_group.sks.name]
  }

  ingress {
    description = "Nodes logs/exec"
    protocol  = "TCP"
    ports     = ["10250"]
    user_security_group_list = [exoscale_security_group.sks.name]
  }

  ingress {
    description = "NodePort services"
    protocol    = "TCP"
    cidr_list   = ["0.0.0.0/0", "::/0"]
    ports       = ["30000-32767"]
  }
}

resource "exoscale_sks_cluster" "prod" {
  zone    = local.zone
  name    = "${var.project}-prod"
}

resource "exoscale_sks_nodepool" "nodepool" {

  zone               = local.zone
  cluster_id         = exoscale_sks_cluster.prod.id
  name               = "${var.project}-nodepool"
  instance_type      = "standard.medium"
  size               = 3
  security_group_ids = [exoscale_security_group.sks.id]
}

resource "exoscale_sks_kubeconfig" "prod_admin" {
  zone = local.zone
  ttl_seconds = 360000
  early_renewal_seconds = 300
  cluster_id = exoscale_sks_cluster.prod.id
  user = "${var.project}-admin"
  groups = ["system:masters"]
}

resource "local_file" "kube_config" {
  content = exoscale_sks_kubeconfig.prod_admin.kubeconfig
  filename = "kube_config"
}

resource "exoscale_database" "pgprod" {
  zone = local.zone
  name = "${var.project}-prod"
  type = "pg"
  plan = "startup-8"

  maintenance_dow  = "sunday"
  maintenance_time = "23:00:00"

  termination_protection = true
  pg {
    version 	  	 = "14"
    backup_schedule	 = "01:00"
    ip_filter    	 = ["0.0.0.0/0"]
    admin_username	 = "avnadmin"
    admin_password	 = var.exoscale_pgsql_pwd
  }
}

resource "local_file" "db-secret" {
 content = <<EOF
PGHOST=${element(split(":",element(split("@",exoscale_database.pgprod.uri),1)),0)}
PGPORT=21699
PGUSER=${var.exoscale_pgsql_user}
PGPASSWORD=${var.exoscale_pgsql_pwd}
PGDATABASE=exoscale-order
PGSSLMODE=require
EOF
 filename = "db-secret.sh"
}

resource "null_resource" "sec_priv_reg" {
  provisioner "local-exec" {
    command      = "kubectl --kubeconfig kube_config create secret docker-registry regcred --docker-server=exo.container-registry.com --docker-username=${var.exoscale_priv_reg_user} --docker-password=${var.exoscale_priv_reg_pwd}"
  }
  depends_on = [
    resource.local_file.kube_config # optional if need to fit this in with other preceding resource
  ]
}

resource "null_resource" "sec_db_cred" {
  provisioner "local-exec" {
    command      = "kubectl --kubeconfig kube_config create secret generic order-pg-credentials --from-env-file=db-secret.sh"
  }
  depends_on = [
    resource.local_file.kube_config # optional if need to fit this in with other preceding resource
  ]
}

resource "null_resource" "sleep" {
  provisioner "local-exec" {
    command      = "sleep 100"
  }
  depends_on = [
    resource.null_resource.sec_db_cred # optional if need to fit this in with other preceding resource
  ]
}

resource "null_resource" "sql_prep" {
  provisioner "local-exec" {
    command      = "psql ${exoscale_database.pgprod.uri} -f ../exoscale-order-party-backend/sql/order.sql"
  }
  depends_on = [
    resource.null_resource.sleep # optional if need to fit this in with other preceding resource
  ]
}

resource "null_resource" "k8s_ingress" {
  provisioner "local-exec" {
    command      = "kubectl --kubeconfig kube_config apply -f ingress-nginx-controller.yaml"
  }
  depends_on = [
    resource.null_resource.sql_prep # optional if need to fit this in with other preceding resource
  ]
}

resource "null_resource" "sleep2" {
  provisioner "local-exec" {
    command      = "sleep 30"
  }
  depends_on = [
    resource.null_resource.k8s_ingress # optional if need to fit this in with other preceding resource
  ]
}

resource "null_resource" "k8s_app" {
  provisioner "local-exec" {
    command      = "kubectl --kubeconfig kube_config apply -f app.yaml"
  }
  depends_on = [
    resource.null_resource.sleep2 # optional if need to fit this in with other preceding resource
  ]
}
