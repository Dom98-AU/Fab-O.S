#!/usr/bin/env python3
import subprocess
import time
import os

# Use wkhtmltoimage or similar tool if available
def capture_screenshot():
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    
    # First, let's try to login using curl and save cookies
    print("Attempting to login...")
    
    # Get login page to extract any tokens
    login_cmd = [
        "curl", "-c", "cookies.txt", "-s", 
        "http://localhost:8080/Identity/Account/Login"
    ]
    
    result = subprocess.run(login_cmd, capture_output=True, text=True)
    
    # Now attempt login with credentials
    login_post = [
        "curl", "-b", "cookies.txt", "-c", "cookies.txt",
        "-X", "POST",
        "-d", "Input.Email=admin@steelestimation.com",
        "-d", "Input.Password=Admin@123",
        "-d", "Input.RememberMe=false",
        "-L", "-s",
        "http://localhost:8080/Identity/Account/Login"
    ]
    
    result = subprocess.run(login_post, capture_output=True, text=True)
    
    # Now capture the main page with cookies
    main_page = [
        "curl", "-b", "cookies.txt", "-s",
        "http://localhost:8080/"
    ]
    
    result = subprocess.run(main_page, capture_output=True, text=True)
    
    # Save the HTML
    with open(f"sidebar-page-{timestamp}.html", "w") as f:
        f.write(result.stdout)
    
    print(f"Page HTML saved to sidebar-page-{timestamp}.html")
    
    # Try to extract sidebar info from HTML
    if "sidebar" in result.stdout.lower():
        print("\nSidebar found in HTML!")
        # Count navigation items
        nav_count = result.stdout.lower().count('nav-link')
        print(f"Found {nav_count} navigation links")
        
        # Check for logo
        if "logo" in result.stdout.lower() or "fab" in result.stdout.lower():
            print("Logo reference found")
    else:
        print("\nNo sidebar found in HTML response")
    
    return f"sidebar-page-{timestamp}.html"

if __name__ == "__main__":
    filename = capture_screenshot()
    print(f"\nHTML content saved. You can open {filename} in a browser to view the page.")
    
    # Clean up cookies file
    if os.path.exists("cookies.txt"):
        os.remove("cookies.txt")