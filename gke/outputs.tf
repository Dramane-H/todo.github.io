output "subnet" {
  value = google_compute_subnetwork.custom.id
}

output "network" {
  value = google_compute_network.custom.id
}

output "gke_cluster" {
  value = google_container_cluster.my_vpc_native_cluster.id
}