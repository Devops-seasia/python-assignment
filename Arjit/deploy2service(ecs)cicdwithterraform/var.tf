variable "artifacts_bucket_name" {
  description = "S3 Bucket for storing artifacts"
  default     = "djangoreacttesting"
}

variable "env" {
  description = "Depolyment environment"
  default     = "dev"
}