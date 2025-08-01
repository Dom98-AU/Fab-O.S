#!/usr/bin/env python3
import requests
import json
from bs4 import BeautifulSoup
import time

print("Testing Steel Estimation Platform UI\n")

# Base URL
base_url = "http://localhost:8080"

# Create a session to maintain cookies
session = requests.Session()

print("1. Testing connection to application...")
try:
    response = session.get(base_url, timeout=10)
    print(f"   - Main page status: {response.status_code}")
    print(f"   - Response size: {len(response.content)} bytes")
except Exception as e:
    print(f"   - Error connecting to {base_url}: {e}")

print("\n2. Accessing login page...")
try:
    login_url = f"{base_url}/Account/Login"
    response = session.get(login_url, timeout=10)
    print(f"   - Login page status: {response.status_code}")
    print(f"   - URL: {response.url}")
    
    # Parse the login page
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find form elements
    form = soup.find('form', method='post')
    if form:
        print("   - Login form found")
        
        # Find input fields
        email_input = soup.find('input', {'name': 'Input.Email'}) or soup.find('input', {'id': 'Input_Email'})
        password_input = soup.find('input', {'name': 'Input.Password'}) or soup.find('input', {'id': 'Input_Password'})
        
        if email_input:
            print(f"   - Email input found: name='{email_input.get('name', 'N/A')}', id='{email_input.get('id', 'N/A')}'")
        if password_input:
            print(f"   - Password input found: name='{password_input.get('name', 'N/A')}', id='{password_input.get('id', 'N/A')}'")
        
        # Look for CSRF token
        csrf_token = None
        csrf_input = soup.find('input', {'name': '__RequestVerificationToken'})
        if csrf_input:
            csrf_token = csrf_input.get('value')
            print(f"   - CSRF token found: {csrf_token[:20]}..." if csrf_token else "   - No CSRF token value")
        
        # Save login page HTML for debugging
        with open('login-page-parsed.html', 'w', encoding='utf-8') as f:
            f.write(response.text)
        print("   - Login page saved to login-page-parsed.html")
        
    else:
        print("   - No login form found")
        print("   - Page title:", soup.title.string if soup.title else "No title")
        
except Exception as e:
    print(f"   - Error accessing login page: {e}")

print("\n3. Attempting login...")
try:
    # Prepare login data
    login_data = {
        'Input.Email': 'admin@steelestimation.com',
        'Input.Password': 'Admin@123'
    }
    
    # Add CSRF token if found
    if csrf_token:
        login_data['__RequestVerificationToken'] = csrf_token
    
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Referer': login_url
    }
    
    print(f"   - Posting to: {login_url}")
    print(f"   - Data fields: {list(login_data.keys())}")
    
    response = session.post(login_url, data=login_data, headers=headers, allow_redirects=False)
    print(f"   - Login response status: {response.status_code}")
    print(f"   - Response headers: {dict(response.headers)}")
    
    if response.status_code in [301, 302, 303, 307]:
        redirect_url = response.headers.get('Location')
        print(f"   - Redirect to: {redirect_url}")
        
        # Follow redirect
        if redirect_url:
            if not redirect_url.startswith('http'):
                redirect_url = base_url + redirect_url
            response = session.get(redirect_url)
            print(f"   - Final page status: {response.status_code}")
            print(f"   - Final URL: {response.url}")
    
    # Check if login was successful
    if 'logout' in response.text.lower() or 'sign out' in response.text.lower():
        print("   - Login appears successful (logout option found)")
    else:
        print("   - Login may have failed (no logout option found)")
        
        # Check for error messages
        soup = BeautifulSoup(response.text, 'html.parser')
        errors = soup.find_all(class_=['text-danger', 'alert-danger', 'validation-summary-errors'])
        if errors:
            print("   - Error messages found:")
            for error in errors:
                print(f"     * {error.get_text(strip=True)}")
    
    # Save response for debugging
    with open('after-login.html', 'w', encoding='utf-8') as f:
        f.write(response.text)
    print("   - Response saved to after-login.html")
    
except Exception as e:
    print(f"   - Error during login: {e}")

print("\n4. Session cookies:")
for cookie in session.cookies:
    print(f"   - {cookie.name}: {cookie.value[:20]}..." if len(cookie.value) > 20 else f"   - {cookie.name}: {cookie.value}")

print("\n=== Test Summary ===")
print("Check the saved HTML files for more details:")
print("- login-page-parsed.html: The login page")
print("- after-login.html: The page after login attempt")