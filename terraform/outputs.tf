output "master_ip" {
  value = "192.168.1.104"
}

output "worker_ips" {
  value = [for i in range(2) : "192.168.1.${105 + i}"]
}