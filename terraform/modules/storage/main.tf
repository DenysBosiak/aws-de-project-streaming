data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "raw" {
    bucket = "p1-events-raw-${var.env}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "scripts" {
    bucket = "p1-scripts-${var.env}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "raw" {
    bucket = aws_s3_bucket.raw.id
    rule {
        id     = "tiering"
        status = "Enabled"
        transition { 
            days = 30 
            storage_class = "STANDARD_IA"
        }
        transition { 
            days = 90 
            storage_class = "GLACIER_IR"
        }
        transition { 
            days = 365
            storage_class = "DEEP_ARCHIVE"
        }                
    }
}

resource "aws_glue_registry" "events" {
    registry_name = "ecommerce-events-${var.env}"
}