terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.79"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
  }
}
provider "aws" {
  region = "us-west-2"
}

################################################################################
# API Gateway Module
################################################################################

module "flexible_apigw" {
  source = ""

  routes = {
    "/users" = {
      method = ["GET", "POST", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
      }
    }

    "/users/{userId+}" = {
      method = ["GET", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
        method_request_parameters = {
          "method.request.path.userId" = true
        }
      }
    }

    "/users/ui/{component}/metadata" = {
      method = ["GET", "POST", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
      }
    }
    "/orders" = {
      method = ["GET", "POST", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
      }
    }
  }
}
