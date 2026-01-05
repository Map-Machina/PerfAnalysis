#!/bin/bash
# Create a new user account in XATbackend
# Usage: ./scripts/create_user.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}================================================================"
echo "Create New User Account for XATbackend Portal"
echo "================================================================${NC}"
echo ""

# Get user input
read -p "Enter username: " USERNAME
read -p "Enter email: " EMAIL
read -s -p "Enter password: " PASSWORD
echo ""
read -p "First name (optional): " FIRSTNAME
read -p "Last name (optional): " LASTNAME

# Set defaults
FIRSTNAME=${FIRSTNAME:-"User"}
LASTNAME=${LASTNAME:-""}

echo ""
echo -e "${YELLOW}Creating user account...${NC}"

# Create user via Django shell
docker-compose exec -T xatbackend python manage.py shell <<CREATEUSER 2>&1 | grep -v Warning
from django.contrib.auth.models import User
from allauth.account.models import EmailAddress

username = "${USERNAME}"
email = "${EMAIL}"
password = "${PASSWORD}"
first_name = "${FIRSTNAME}"
last_name = "${LASTNAME}"

# Check if user exists
if User.objects.filter(username=username).exists():
    print(f"✗ Error: User '{username}' already exists")
    exit(1)

if User.objects.filter(email=email).exists():
    print(f"✗ Error: Email '{email}' is already registered")
    exit(1)

# Create user
user = User.objects.create_user(
    username=username,
    email=email,
    password=password,
    first_name=first_name,
    last_name=last_name
)

# Create EmailAddress for allauth
email_obj = EmailAddress.objects.create(
    user=user,
    email=email,
    verified=True,
    primary=True
)

print(f"✓ Successfully created user account")
print(f"  Username:   {username}")
print(f"  Email:      {email}")
print(f"  Name:       {first_name} {last_name}")
print(f"  User ID:    {user.pk}")

CREATEUSER

echo ""
echo -e "${GREEN}================================================================"
echo "✓ User Account Created Successfully!"
echo "================================================================${NC}"
echo ""
echo -e "${CYAN}Login to the portal:${NC}"
echo "  URL:      http://localhost:8000/auth/login/"
echo "  Email:    ${EMAIL}"
echo "  Password: (the password you just entered)"
echo ""
echo -e "${CYAN}Available credentials:${NC}"
echo ""
echo "  ${BLUE}Admin Account:${NC}"
echo "    Email:    admin@perfanalysis.com"
echo "    Password: admin123"
echo ""
echo "  ${BLUE}New User Account:${NC}"
echo "    Email:    ${EMAIL}"
echo "    Password: (your password)"
echo ""
echo -e "${GREEN}You can now log in with either account!${NC}"
echo ""
