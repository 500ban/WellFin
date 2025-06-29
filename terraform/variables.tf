variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "your-gcp-project-id"
}

variable "region" {
  description = "GCP Region for Cloud Run Functions"
  type        = string
  default     = "asia-northeast1"
}

variable "wellfin_api_key" {
  description = "WellFin API Key for authentication"
  type        = string
  default     = "dev-secret-key"
  sensitive   = true
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "org_id" {
  description = "GCP Organization ID (optional)"
  type        = string
  default     = null
}


