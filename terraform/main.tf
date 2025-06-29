# 必要なAPIの有効化（必要最小限）
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "aiplatform.googleapis.com", 
    "cloudbuild.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# サービスアカウント作成
resource "google_service_account" "ai_function" {
  account_id   = "wellfin-ai-function"
  display_name = "WellFin AI Function Service Account"
  project      = var.project_id
  
  depends_on = [google_project_service.required_apis]
}

# IAM権限付与（手動構築分を統合）
resource "google_project_iam_member" "ai_function_roles" {
  for_each = toset([
    "roles/aiplatform.admin",  # 手動追加分を統合 (was: aiplatform.user)
    "roles/iam.serviceAccountTokenCreator",  # 手動追加分を統合 (new)
    "roles/logging.logWriter"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ai_function.email}"
  
  depends_on = [google_service_account.ai_function]
}

# Cloud Storage bucket for function source code
resource "google_storage_bucket" "function_source" {
  name          = "${var.project_id}-wellfin-ai-function-source"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  depends_on = [google_project_service.required_apis]
}

# Zip the function source code
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "../functions"
  output_path = "/tmp/wellfin-ai-function.zip"
  excludes    = [
    "node_modules",
    ".git",
    ".gitignore",
    "*.log",
    "Dockerfile",
    "*.bat"
  ]
}

# Upload function source to Cloud Storage
resource "google_storage_bucket_object" "function_source" {
  name   = "wellfin-ai-function-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path
  
  depends_on = [google_storage_bucket.function_source, data.archive_file.function_source]
}

# Cloud Run Function (Generation 2)
resource "google_cloudfunctions2_function" "ai_function" {
  name        = "wellfin-ai-function"
  location    = var.region
  project     = var.project_id
  description = "WellFin AI Agent API"

  build_config {
    runtime     = "nodejs22"  # 手動デプロイ設定と統合 (was: nodejs20)
    entry_point = "app"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "1Gi"
    timeout_seconds       = 60
    max_instance_request_concurrency = 80
    available_cpu         = "1"
    
    environment_variables = {
      NODE_ENV = var.environment
      ENVIRONMENT = var.environment
      WELLFIN_API_KEY = var.wellfin_api_key
      GOOGLE_CLOUD_PROJECT = var.project_id
      VERTEX_AI_LOCATION = var.region
      # Cloud Run Functionsでは自動認証を使用するため、明示的にクリア
      GOOGLE_APPLICATION_CREDENTIALS = ""
    }
    
    service_account_email = google_service_account.ai_function.email
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.ai_function,
    google_storage_bucket_object.function_source
  ]
}

# IAM for Cloud Run Functions - APIキー認証のため、一般アクセスを許可
resource "google_cloudfunctions2_function_iam_member" "public_access" {
  project        = google_cloudfunctions2_function.ai_function.project
  location       = google_cloudfunctions2_function.ai_function.location
  cloud_function = google_cloudfunctions2_function.ai_function.name
  role           = "roles/cloudfunctions.invoker"  # 手動設定と統合 (was: run.invoker)
  member         = "allUsers"
  
  depends_on = [google_cloudfunctions2_function.ai_function]
}


