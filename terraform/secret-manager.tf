# Secret Manager for Production API Key Management

# Secret Manager API有効化
resource "google_project_service" "secret_manager" {
  count   = var.environment == "production" ? 1 : 0
  project = var.project_id
  service = "secretmanager.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# API Key Secret（本番環境のみ）
resource "google_secret_manager_secret" "wellfin_api_key" {
  count     = var.environment == "production" ? 1 : 0
  project   = var.project_id
  secret_id = "wellfin-api-key"
  
  labels = {
    environment = var.environment
    service     = "wellfin-ai-agent"
    managed_by  = "terraform"
  }
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  
  depends_on = [google_project_service.secret_manager]
}

# API Key Secret Version（本番環境のみ）
resource "google_secret_manager_secret_version" "wellfin_api_key" {
  count   = var.environment == "production" ? 1 : 0
  secret  = google_secret_manager_secret.wellfin_api_key[0].id
  
  # 本番環境では手動でAPIキーを設定
  # 初期設定後、このリソースをTerraform管理から除外することを推奨
  secret_data = var.wellfin_api_key
  
  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Secret Manager権限付与（本番環境のみ）
resource "google_secret_manager_secret_iam_member" "wellfin_api_key_accessor" {
  count     = var.environment == "production" ? 1 : 0
  project   = var.project_id
  secret_id = google_secret_manager_secret.wellfin_api_key[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ai_function.email}"
  
  depends_on = [google_secret_manager_secret.wellfin_api_key]
}

# 本番環境用のCloud Run Functions設定（Secret Manager使用）
locals {
  # 本番環境ではSecret Managerから取得、それ以外は変数から取得
  environment_variables_with_secrets = var.environment == "production" ? {
    NODE_ENV             = var.environment
    ENVIRONMENT          = var.environment
    GOOGLE_CLOUD_PROJECT = var.project_id
    VERTEX_AI_LOCATION   = var.region
    # WELLFIN_API_KEY は secrets で設定
  } : {
    NODE_ENV             = var.environment
    ENVIRONMENT          = var.environment
    WELLFIN_API_KEY      = var.wellfin_api_key
    GOOGLE_CLOUD_PROJECT = var.project_id
    VERTEX_AI_LOCATION   = var.region
  }
  
  # 本番環境でのSecret設定
  secret_environment_variables = var.environment == "production" ? [
    {
      key        = "WELLFIN_API_KEY"
      project_id = var.project_id
      secret     = google_secret_manager_secret.wellfin_api_key[0].secret_id
      version    = "latest"
    }
  ] : []
}

# Cloud Run Functions設定の更新
resource "google_cloudfunctions2_function" "ai_function_with_secrets" {
  count       = var.environment == "production" ? 1 : 0
  name        = "wellfin-ai-function"
  location    = var.region
  project     = var.project_id
  description = "WellFin AI Agent API (Production with Secret Manager)"

  build_config {
    runtime     = "nodejs22"
    entry_point = "app"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count               = 10
    min_instance_count               = 0
    available_memory                 = "1Gi"
    timeout_seconds                  = 60
    max_instance_request_concurrency = 80
    available_cpu                    = "1"
    
    environment_variables = local.environment_variables_with_secrets
    
    # Secret Manager から API Key を取得
    dynamic "secret_environment_variables" {
      for_each = local.secret_environment_variables
      content {
        key        = secret_environment_variables.value.key
        project_id = secret_environment_variables.value.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }
    
    service_account_email = google_service_account.ai_function.email
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_account.ai_function,
    google_storage_bucket_object.function_source,
    google_secret_manager_secret_iam_member.wellfin_api_key_accessor
  ]
} 