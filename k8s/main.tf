locals {
  zone = "CH-DK-2"
}

terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
    }
  }
}


provider "exoscale" {
  key    = "${var.exoscale_api_key}"
  secret = "${var.exoscale_api_secret}"
}

resource "exoscale_security_group" "sks" {
  name = "${var.project}-sks"
}

resource "exoscale_security_group_rule" "calico-traffic" {
  security_group_id = exoscale_security_group.sks.id
  type = "INGRESS"
  protocol = "UDP"
  start_port = "4789"
  end_port = "4789"
  user_security_group_id = exoscale_security_group.sks.id
}

resource "exoscale_security_group_rule" "nodes-logs-exec" {
  security_group_id = exoscale_security_group.sks.id
  type = "INGRESS"
  protocol = "TCP"
  start_port = "10250"
  end_port = "10250"
  user_security_group_id = exoscale_security_group.sks.id
}

resource "exoscale_security_group_rule" "nodeport-services-ipv4" {
  security_group_id = exoscale_security_group.sks.id
  type = "INGRESS"
  protocol = "TCP"
  start_port = "30000"
  end_port = "32767"
  cidr = "0.0.0.0/0"
}

resource "exoscale_security_group_rule" "nodeport-services-ipv6" {
  security_group_id = exoscale_security_group.sks.id
  type = "INGRESS"
  protocol = "TCP"
  start_port = "30000"
  end_port = "32767"
  cidr = "::/0"
}


resource "exoscale_sks_cluster" "prod" {
  zone    = local.zone
  name    = "${var.project}-prod"
  depends_on         = [exoscale_security_group.sks, exoscale_security_group_rule.calico-traffic, exoscale_security_group_rule.nodes-logs-exec, exoscale_security_group_rule.nodeport-services-ipv4, exoscale_security_group_rule.nodeport-services-ipv6 ]
}

resource "exoscale_sks_nodepool" "nodepool" {

  zone               = local.zone
  cluster_id         = exoscale_sks_cluster.prod.id
  name               = "${var.project}-nodepool"
  instance_type      = "standard.medium"
  size               = 3
  security_group_ids = [exoscale_security_group.sks.id]
  depends_on         = [exoscale_security_group.sks]
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

  termination_protection = false
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
    command      = "export PGPASSWORD='${var.exoscale_pgsql_pwd}'; psql ${exoscale_database.pgprod.uri} -f ../exoscale-order-party-backend/sql/order.sql"
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
