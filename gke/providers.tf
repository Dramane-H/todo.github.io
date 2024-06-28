terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.35.0"
    }
  }
}

provider "google" {
  credentials = file("../gke/creds.json")
  region      = "us-central1"
}