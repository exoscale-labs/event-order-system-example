
provider "exoscale" {
  alias  = "dns"
  key    = "${var.exoscale_dns_api_key}"
  secret = "${var.exoscale_dns_api_secret}"
}

resource "null_resource" "getsvcip" {
  provisioner "local-exec" {
    #command      = "> ingress_ips.txt; until ! kubectl --kubeconfig kube_config get service --all-namespaces |grep LoadBalancer |grep ingress-nginx | grep pending; do echo still pending; sleep 5;done;  kubectl --kubeconfig kube_config get service --all-namespaces |grep LoadBalancer |grep ingress-nginx |awk '{print $5}' > ingress_ips.txt"
    command      = "> ingress_ips.txt; until ! kubectl --kubeconfig kube_config get services/ingress-nginx-controller -n ingress-nginx | grep pending; do echo still pending; sleep 5;done;  kubectl --kubeconfig kube_config get services/ingress-nginx-controller -n ingress-nginx |grep ingress-nginx |awk '{print $4}' > ingress_ips.txt"
  }
  depends_on = [
    resource.null_resource.k8s_app # optional if need to fit this in with other preceding resource
  ]
}

data "local_file" "ingress-ip" {
    filename = "ingress_ips.txt"
  depends_on = [
    resource.null_resource.getsvcip
  ]
}

resource "exoscale_domain_record" "frontend-dns" {
  provider    = exoscale.dns
  domain      = "cldsvc.io"
  name        = "order"
  record_type = "A"
  ttl         = "60"
  content     = "${data.local_file.ingress-ip.content}"
}

resource "exoscale_domain_record" "backend-dns" {
  provider    = exoscale.dns
  domain      = "cldsvc.io"
  name        = "exoscale-order-backend"
  record_type = "A"
  ttl         = "60"
  content     = "${data.local_file.ingress-ip.content}"
}
