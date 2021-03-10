terraform {
  required_version = ">= 0.12.6"
}

provider "google-beta" {
  credentials = file("urban-piper-gcp-staging-df304ddf76f8.json")
  project     = "urban-piper-gcp-staging"
  region      = "us-west1"
}
provider "google" {
  credentials = file("urban-piper-gcp-staging-df304ddf76f8.json")
  project     = "urban-piper-gcp-staging"
  region      = "us-west1"
}