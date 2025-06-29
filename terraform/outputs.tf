output "function_url" {
  description = "Cloud Run Function URL"
  value       = google_cloudfunctions2_function.ai_function.url
}

output "function_name" {
  description = "Cloud Run Function Name"
  value       = google_cloudfunctions2_function.ai_function.name
}

output "service_account_email" {
  description = "AI Function Service Account Email"
  value       = google_service_account.ai_function.email
}

output "storage_bucket" {
  description = "Function Source Storage Bucket"
  value       = google_storage_bucket.function_source.name
}



