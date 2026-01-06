#!/bin/bash
#===============================================================================
# Azure Minimal Deployment Script for PerfAnalysis
#
# This script deploys PerfAnalysis to Azure using the Phase 1 configuration:
# - Azure App Service (S1 tier) for Django XATbackend
# - Azure PostgreSQL Flexible Server (B1ms) for database
# - Optional: Blob Storage, Application Insights (Phase 2-3)
#
# Prerequisites:
# - Azure CLI installed and logged in (az login)
# - Git repository with XATbackend code
# - Python 3.9+ for local testing
#
# Usage:
#   ./azure_deploy.sh                    # Interactive mode
#   ./azure_deploy.sh --phase 1          # Deploy Phase 1 only
#   ./azure_deploy.sh --phase 2          # Deploy Phase 1 + Blob Storage
#   ./azure_deploy.sh --phase 3          # Deploy Phase 1-2 + Monitoring
#   ./azure_deploy.sh --teardown         # Remove all resources
#
# Cost Estimates:
#   Phase 1: ~$82/month (recommended minimum)
#   Phase 2: ~$83/month (+ Blob Storage)
#   Phase 3: ~$95/month (+ Application Insights)
#
# Author: PerfAnalysis Team
# Date: January 2026
#===============================================================================

set -e  # Exit on error

#-------------------------------------------------------------------------------
# Configuration - CUSTOMIZE THESE VALUES
#-------------------------------------------------------------------------------

# Resource naming (must be globally unique for some services)
RESOURCE_GROUP="perfanalysis-rg"
LOCATION="eastus"
APP_NAME="perfanalysis-app"
APP_SERVICE_PLAN="perfanalysis-plan"
DB_SERVER_NAME="perfanalysis-db"
STORAGE_ACCOUNT_NAME="perfanalysisstor"  # Must be lowercase, no hyphens, 3-24 chars
APP_INSIGHTS_NAME="perfanalysis-insights"

# Database configuration
DB_ADMIN_USER="perfadmin"
DB_NAME="perfanalysis"
DB_SKU="Standard_B1ms"
DB_STORAGE_SIZE=32  # GB

# App Service configuration
APP_SERVICE_SKU="S1"  # S1 for Phase 1, B1 for Phase 0
PYTHON_VERSION="3.9"

# Django configuration
DJANGO_SETTINGS_MODULE="core.settings"
ALLOWED_HOSTS=""  # Will be set dynamically

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XATBACKEND_DIR="$PROJECT_ROOT/XATbackend"

#-------------------------------------------------------------------------------
# Colors for output
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Helper functions
#-------------------------------------------------------------------------------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

generate_password() {
    # Generate a strong random password
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%' | head -c 24
}

generate_secret_key() {
    # Generate Django secret key
    openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 50
}

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first:"
        echo "  brew install azure-cli  # macOS"
        echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Linux"
        exit 1
    fi

    # Check if logged in
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Please run: az login"
        exit 1
    fi

    log_success "Azure CLI is installed and logged in"

    # Show current subscription
    SUBSCRIPTION=$(az account show --query name -o tsv)
    log_info "Using subscription: $SUBSCRIPTION"
}

check_prerequisites() {
    log_step "Checking Prerequisites"

    check_azure_cli

    # Check if XATbackend directory exists
    if [ ! -d "$XATBACKEND_DIR" ]; then
        log_error "XATbackend directory not found at: $XATBACKEND_DIR"
        exit 1
    fi
    log_success "XATbackend directory found"

    # Check for requirements.txt
    if [ ! -f "$XATBACKEND_DIR/requirements.txt" ]; then
        log_error "requirements.txt not found in XATbackend"
        exit 1
    fi
    log_success "requirements.txt found"
}

#-------------------------------------------------------------------------------
# Phase 0: Resource Group
#-------------------------------------------------------------------------------

create_resource_group() {
    log_step "Creating Resource Group"

    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "Resource group '$RESOURCE_GROUP' already exists"
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --output none
        log_success "Created resource group: $RESOURCE_GROUP"
    fi
}

#-------------------------------------------------------------------------------
# Phase 1: App Service + PostgreSQL
#-------------------------------------------------------------------------------

create_app_service_plan() {
    log_step "Creating App Service Plan"

    if az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "App Service Plan '$APP_SERVICE_PLAN' already exists"
    else
        az appservice plan create \
            --name "$APP_SERVICE_PLAN" \
            --resource-group "$RESOURCE_GROUP" \
            --sku "$APP_SERVICE_SKU" \
            --is-linux \
            --output none
        log_success "Created App Service Plan: $APP_SERVICE_PLAN (SKU: $APP_SERVICE_SKU)"
    fi
}

create_web_app() {
    log_step "Creating Web App"

    if az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "Web App '$APP_NAME' already exists"
    else
        az webapp create \
            --name "$APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --plan "$APP_SERVICE_PLAN" \
            --runtime "PYTHON:$PYTHON_VERSION" \
            --output none
        log_success "Created Web App: $APP_NAME"
    fi

    # Get the default hostname
    WEBAPP_URL=$(az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostName -o tsv)
    log_info "Web App URL: https://$WEBAPP_URL"
}

create_postgresql() {
    log_step "Creating PostgreSQL Flexible Server"

    # Generate password if not set
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(generate_password)
        log_info "Generated database password (save this!): $DB_PASSWORD"
    fi

    if az postgres flexible-server show --name "$DB_SERVER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "PostgreSQL server '$DB_SERVER_NAME' already exists"
    else
        log_info "Creating PostgreSQL server (this may take 5-10 minutes)..."

        az postgres flexible-server create \
            --name "$DB_SERVER_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --admin-user "$DB_ADMIN_USER" \
            --admin-password "$DB_PASSWORD" \
            --sku-name "$DB_SKU" \
            --tier Burstable \
            --storage-size "$DB_STORAGE_SIZE" \
            --version 14 \
            --yes \
            --output none

        log_success "Created PostgreSQL server: $DB_SERVER_NAME"
    fi

    # Allow Azure services to access the database
    log_info "Configuring firewall rules..."
    az postgres flexible-server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DB_SERVER_NAME" \
        --rule-name AllowAzureServices \
        --start-ip-address 0.0.0.0 \
        --end-ip-address 0.0.0.0 \
        --output none 2>/dev/null || true

    # Create the database
    log_info "Creating database..."
    az postgres flexible-server db create \
        --resource-group "$RESOURCE_GROUP" \
        --server-name "$DB_SERVER_NAME" \
        --database-name "$DB_NAME" \
        --output none 2>/dev/null || true

    log_success "PostgreSQL setup complete"

    # Get connection string
    DB_HOST="$DB_SERVER_NAME.postgres.database.azure.com"
    log_info "Database host: $DB_HOST"
}

configure_app_settings() {
    log_step "Configuring App Settings"

    # Generate Django secret key
    DJANGO_SECRET_KEY=$(generate_secret_key)

    # Get webapp hostname for ALLOWED_HOSTS
    WEBAPP_HOSTNAME=$(az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostName -o tsv)

    # Build database URL
    DATABASE_URL="postgresql://${DB_ADMIN_USER}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME}?sslmode=require"

    log_info "Setting environment variables..."

    az webapp config appsettings set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --settings \
            DEBUG="False" \
            SECRET_KEY="$DJANGO_SECRET_KEY" \
            ALLOWED_HOSTS="$WEBAPP_HOSTNAME,.azurewebsites.net" \
            DATABASE_URL="$DATABASE_URL" \
            DB_HOST="$DB_HOST" \
            DB_NAME="$DB_NAME" \
            DB_USER="$DB_ADMIN_USER" \
            DB_PASSWORD="$DB_PASSWORD" \
            DJANGO_SETTINGS_MODULE="$DJANGO_SETTINGS_MODULE" \
            SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
            WEBSITE_HTTPLOGGING_RETENTION_DAYS="7" \
        --output none

    # Configure startup command
    az webapp config set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 --workers 2 core.wsgi:application" \
        --output none

    log_success "App settings configured"
}

#-------------------------------------------------------------------------------
# Phase 2: Blob Storage
#-------------------------------------------------------------------------------

create_blob_storage() {
    log_step "Creating Blob Storage (Phase 2)"

    # Check if storage account name is valid
    if [[ ${#STORAGE_ACCOUNT_NAME} -lt 3 || ${#STORAGE_ACCOUNT_NAME} -gt 24 ]]; then
        log_error "Storage account name must be 3-24 characters"
        exit 1
    fi

    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "Storage account '$STORAGE_ACCOUNT_NAME' already exists"
    else
        az storage account create \
            --name "$STORAGE_ACCOUNT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --kind StorageV2 \
            --output none
        log_success "Created storage account: $STORAGE_ACCOUNT_NAME"
    fi

    # Get storage account key
    STORAGE_KEY=$(az storage account keys list \
        --resource-group "$RESOURCE_GROUP" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --query '[0].value' -o tsv)

    # Create containers
    log_info "Creating storage containers..."

    az storage container create \
        --name media \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$STORAGE_KEY" \
        --public-access off \
        --output none 2>/dev/null || true

    az storage container create \
        --name static \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$STORAGE_KEY" \
        --public-access blob \
        --output none 2>/dev/null || true

    # Update app settings with storage configuration
    az webapp config appsettings set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --settings \
            AZURE_STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT_NAME" \
            AZURE_STORAGE_ACCOUNT_KEY="$STORAGE_KEY" \
            USE_AZURE_STORAGE="True" \
        --output none

    log_success "Blob storage configured"
}

#-------------------------------------------------------------------------------
# Phase 3: Application Insights
#-------------------------------------------------------------------------------

create_app_insights() {
    log_step "Creating Application Insights (Phase 3)"

    if az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "Application Insights '$APP_INSIGHTS_NAME' already exists"
    else
        az monitor app-insights component create \
            --app "$APP_INSIGHTS_NAME" \
            --location "$LOCATION" \
            --resource-group "$RESOURCE_GROUP" \
            --application-type web \
            --output none
        log_success "Created Application Insights: $APP_INSIGHTS_NAME"
    fi

    # Get instrumentation key
    INSTRUMENTATION_KEY=$(az monitor app-insights component show \
        --app "$APP_INSIGHTS_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query instrumentationKey -o tsv)

    CONNECTION_STRING=$(az monitor app-insights component show \
        --app "$APP_INSIGHTS_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query connectionString -o tsv)

    # Update app settings
    az webapp config appsettings set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --settings \
            APPINSIGHTS_INSTRUMENTATIONKEY="$INSTRUMENTATION_KEY" \
            APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
        --output none

    log_success "Application Insights configured"
    log_info "Instrumentation Key: $INSTRUMENTATION_KEY"
}

#-------------------------------------------------------------------------------
# Deployment
#-------------------------------------------------------------------------------

deploy_code() {
    log_step "Deploying Application Code"

    # Check if we're deploying from local or GitHub
    if [ -d "$XATBACKEND_DIR/.git" ]; then
        log_info "Deploying from local Git repository..."

        # Create deployment zip
        cd "$XATBACKEND_DIR"

        # Create a clean deployment package
        DEPLOY_ZIP="/tmp/perfanalysis_deploy.zip"

        log_info "Creating deployment package..."

        # Exclude unnecessary files
        zip -r "$DEPLOY_ZIP" . \
            -x "*.pyc" \
            -x "__pycache__/*" \
            -x ".git/*" \
            -x ".env" \
            -x "*.sqlite3" \
            -x "media/*" \
            -x "staticfiles/*" \
            -x ".venv/*" \
            -x "venv/*" \
            -x "*.log" \
            > /dev/null

        log_info "Uploading to Azure (this may take a few minutes)..."

        az webapp deployment source config-zip \
            --resource-group "$RESOURCE_GROUP" \
            --name "$APP_NAME" \
            --src "$DEPLOY_ZIP" \
            --output none

        rm -f "$DEPLOY_ZIP"

        cd "$SCRIPT_DIR"

        log_success "Code deployed successfully"
    else
        log_warning "No Git repository found. Please deploy manually or configure GitHub integration."
    fi
}

run_migrations() {
    log_step "Running Database Migrations"

    log_info "Running Django migrations via SSH..."

    # Use Kudu REST API to run migrations
    az webapp ssh --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" << 'SSHEOF'
cd /home/site/wwwroot
python manage.py migrate --noinput
python manage.py collectstatic --noinput
SSHEOF

    log_success "Migrations complete"
}

create_superuser() {
    log_step "Creating Django Superuser"

    read -p "Enter admin email: " ADMIN_EMAIL
    read -s -p "Enter admin password: " ADMIN_PASSWORD
    echo ""

    log_info "Creating superuser..."

    az webapp ssh --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" << SSHEOF
cd /home/site/wwwroot
python manage.py shell << 'PYEOF'
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(email='$ADMIN_EMAIL').exists():
    User.objects.create_superuser('$ADMIN_EMAIL', '$ADMIN_EMAIL', '$ADMIN_PASSWORD')
    print('Superuser created')
else:
    print('Superuser already exists')
PYEOF
SSHEOF

    log_success "Superuser setup complete"
}

#-------------------------------------------------------------------------------
# Teardown
#-------------------------------------------------------------------------------

teardown() {
    log_step "Tearing Down Azure Resources"

    log_warning "This will DELETE ALL resources in resource group: $RESOURCE_GROUP"
    read -p "Are you sure? (yes/no): " CONFIRM

    if [ "$CONFIRM" = "yes" ]; then
        log_info "Deleting resource group and all resources..."
        az group delete --name "$RESOURCE_GROUP" --yes --no-wait
        log_success "Teardown initiated. Resources will be deleted in the background."
    else
        log_info "Teardown cancelled"
    fi
}

#-------------------------------------------------------------------------------
# Status and Info
#-------------------------------------------------------------------------------

show_status() {
    log_step "Deployment Status"

    # Check resource group
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        log_success "Resource Group: $RESOURCE_GROUP exists"
    else
        log_error "Resource Group: $RESOURCE_GROUP not found"
        return
    fi

    # Check App Service
    if az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        WEBAPP_URL=$(az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostName -o tsv)
        WEBAPP_STATE=$(az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query state -o tsv)
        log_success "Web App: https://$WEBAPP_URL (State: $WEBAPP_STATE)"
    else
        log_warning "Web App: Not deployed"
    fi

    # Check PostgreSQL
    if az postgres flexible-server show --name "$DB_SERVER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        DB_STATE=$(az postgres flexible-server show --name "$DB_SERVER_NAME" --resource-group "$RESOURCE_GROUP" --query state -o tsv)
        log_success "PostgreSQL: $DB_SERVER_NAME.postgres.database.azure.com (State: $DB_STATE)"
    else
        log_warning "PostgreSQL: Not deployed"
    fi

    # Check Storage Account
    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_success "Blob Storage: $STORAGE_ACCOUNT_NAME (Phase 2)"
    else
        log_info "Blob Storage: Not deployed (Phase 2)"
    fi

    # Check Application Insights
    if az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_success "App Insights: $APP_INSIGHTS_NAME (Phase 3)"
    else
        log_info "App Insights: Not deployed (Phase 3)"
    fi

    echo ""
    log_info "To view logs: az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
    log_info "To SSH: az webapp ssh --name $APP_NAME --resource-group $RESOURCE_GROUP"
}

show_credentials() {
    log_step "Deployment Credentials"

    echo ""
    echo "Save these credentials securely!"
    echo "================================"
    echo ""
    echo "Web App URL: https://$(az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostName -o tsv 2>/dev/null || echo 'NOT_DEPLOYED')"
    echo ""
    echo "Database:"
    echo "  Host: $DB_SERVER_NAME.postgres.database.azure.com"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_ADMIN_USER"
    echo "  Password: ${DB_PASSWORD:-'(not set - check Azure Portal)'}"
    echo ""

    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT_NAME" --query '[0].value' -o tsv 2>/dev/null)
        echo "Storage Account:"
        echo "  Name: $STORAGE_ACCOUNT_NAME"
        echo "  Key: ${STORAGE_KEY:-'(check Azure Portal)'}"
        echo ""
    fi
}

show_cost_estimate() {
    log_step "Cost Estimate"

    echo ""
    echo "Monthly Cost Estimate (Pay-as-you-go)"
    echo "======================================"
    echo ""
    echo "Phase 1 (Current):"
    echo "  App Service S1:     \$70/month"
    echo "  PostgreSQL B1ms:    \$12/month"
    echo "  ─────────────────────────────"
    echo "  Total:              \$82/month"
    echo ""

    if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        echo "Phase 2 (Blob Storage):"
        echo "  + Storage (50GB):   \$1/month"
        echo "  ─────────────────────────────"
        echo "  Total:              \$83/month"
        echo ""
    fi

    if az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        echo "Phase 3 (Monitoring):"
        echo "  + App Insights:     \$12/month"
        echo "  ─────────────────────────────"
        echo "  Total:              \$95/month"
        echo ""
    fi

    echo ""
    echo "Cost Optimization Tips:"
    echo "  - 1-year reserved: Save 38% (~\$51/month for Phase 1)"
    echo "  - 3-year reserved: Save 62% (~\$31/month for Phase 1)"
    echo ""
}

#-------------------------------------------------------------------------------
# Main Menu
#-------------------------------------------------------------------------------

show_menu() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║         PerfAnalysis Azure Deployment Script                       ║"
    echo "╠═══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                    ║"
    echo "║  1) Deploy Phase 1 (App Service + PostgreSQL)     ~\$82/month      ║"
    echo "║  2) Deploy Phase 2 (+ Blob Storage)               ~\$83/month      ║"
    echo "║  3) Deploy Phase 3 (+ Application Insights)       ~\$95/month      ║"
    echo "║                                                                    ║"
    echo "║  4) Deploy Code Only (update existing deployment)                  ║"
    echo "║  5) Run Migrations                                                 ║"
    echo "║  6) Create Superuser                                               ║"
    echo "║                                                                    ║"
    echo "║  7) Show Status                                                    ║"
    echo "║  8) Show Credentials                                               ║"
    echo "║  9) Show Cost Estimate                                             ║"
    echo "║                                                                    ║"
    echo "║  t) Teardown (DELETE all resources)                                ║"
    echo "║  q) Quit                                                           ║"
    echo "║                                                                    ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
}

interactive_mode() {
    while true; do
        show_menu
        read -p "Select option: " CHOICE

        case $CHOICE in
            1)
                check_prerequisites
                create_resource_group
                create_app_service_plan
                create_web_app
                create_postgresql
                configure_app_settings
                deploy_code
                show_status
                show_credentials
                ;;
            2)
                check_prerequisites
                create_resource_group
                create_app_service_plan
                create_web_app
                create_postgresql
                create_blob_storage
                configure_app_settings
                deploy_code
                show_status
                ;;
            3)
                check_prerequisites
                create_resource_group
                create_app_service_plan
                create_web_app
                create_postgresql
                create_blob_storage
                create_app_insights
                configure_app_settings
                deploy_code
                show_status
                ;;
            4)
                deploy_code
                ;;
            5)
                run_migrations
                ;;
            6)
                create_superuser
                ;;
            7)
                show_status
                ;;
            8)
                show_credentials
                ;;
            9)
                show_cost_estimate
                ;;
            t|T)
                teardown
                ;;
            q|Q)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

#-------------------------------------------------------------------------------
# Command Line Arguments
#-------------------------------------------------------------------------------

show_help() {
    echo "PerfAnalysis Azure Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --phase 1|2|3    Deploy specific phase"
    echo "  --deploy-code    Deploy code only"
    echo "  --status         Show deployment status"
    echo "  --credentials    Show credentials"
    echo "  --cost           Show cost estimate"
    echo "  --teardown       Delete all resources"
    echo "  --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive mode"
    echo "  $0 --phase 1          # Deploy Phase 1 (recommended minimum)"
    echo "  $0 --phase 2          # Deploy Phase 1 + Blob Storage"
    echo "  $0 --status           # Check deployment status"
    echo ""
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

main() {
    # Parse command line arguments
    case "${1:-}" in
        --phase)
            check_prerequisites
            create_resource_group
            create_app_service_plan
            create_web_app
            create_postgresql

            case "${2:-1}" in
                2|3)
                    create_blob_storage
                    ;;&
                3)
                    create_app_insights
                    ;;
            esac

            configure_app_settings
            deploy_code
            show_status
            show_credentials
            ;;
        --deploy-code)
            deploy_code
            ;;
        --status)
            show_status
            ;;
        --credentials)
            show_credentials
            ;;
        --cost)
            show_cost_estimate
            ;;
        --teardown)
            teardown
            ;;
        --help|-h)
            show_help
            ;;
        "")
            # Interactive mode
            interactive_mode
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
