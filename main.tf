resource "google_compute_network" "urban-vpc" {
  name                    = "urban-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "urban-subnet-1" {
  name          = "urban-subnet-1-app"
  ip_cidr_range = "10.10.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.urban-vpc.id
}

resource "google_compute_subnetwork" "urban-subnet-2" {
  name          = "urban-subnet-2-db"
  ip_cidr_range = "10.10.2.0/24"
  region        = "us-west1"
  network       = google_compute_network.urban-vpc.id
}


resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta
  name     = "private-ip-test"

  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.urban-vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.urban-vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name                = "db-urban-1"
  region              = "us-west1"
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-n1-standard-4"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.urban-vpc.id
    }
  }
}

resource "google_sql_user" "sql_users" {
  name     = "urban-admin"
  instance = google_sql_database_instance.instance.name
  password = "qwerty123"
}

resource "google_redis_instance" "urban-cache" {
  project        = "urban-piper-gcp-staging"
  name           = "urban-cache"
  memory_size_gb = 1
  redis_version  = "REDIS_5_0"
  display_name   = "urban Instance"

  location_id             = "us-west1-a"
  alternative_location_id = "asia-southeast1-a"

}


resource "google_container_cluster" "urban-vpc" {
  name        = var.name
  project     = var.project
  description = "urban GKE Cluster"
  location    = var.location

  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.urban-vpc.id
  subnetwork               = google_compute_subnetwork.urban-subnet-1.name
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "urban-node" {
  name     = "${var.name}-node-pool"
  project  = var.project
  location = var.location
  cluster  = google_container_cluster.urban-vpc.name

  node_count = 1

  node_config {
    preemptible  = false
    machine_type = var.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
