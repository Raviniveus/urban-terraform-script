output "endpoint" {
  value = google_container_cluster.urban-vpc.endpoint
}

output "master_version" {
  value = google_container_cluster.urban-vpc.master_version
}