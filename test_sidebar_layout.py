#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import re
import json

def test_sidebar_layout():
    """Test the sidebar layout of the application"""
    
    print("=" * 60)
    print("SIDEBAR LAYOUT TEST - http://localhost:8080")
    print("=" * 60)
    
    try:
        # Fetch the page
        response = requests.get('http://localhost:8080', timeout=10)
        response.raise_for_status()
        
        print("\n✓ Successfully connected to application")
        print(f"  Status Code: {response.status_code}")
        
        # Parse HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Check for sidebar element
        sidebar = soup.find(class_='sidebar') or soup.find(id='main-sidebar')
        
        print("\n=== SIDEBAR STRUCTURE ===")
        if sidebar:
            print("✓ Sidebar element found")
            
            # Check sidebar classes
            sidebar_classes = sidebar.get('class', [])
            sidebar_id = sidebar.get('id', '')
            print(f"  Classes: {' '.join(sidebar_classes)}")
            print(f"  ID: {sidebar_id}")
            
            # Check for NavMenu inside sidebar
            nav_menu = sidebar.find('navmenu') or sidebar.find(text=re.compile('NavMenu'))
            if nav_menu or 'NavMenu' in str(sidebar):
                print("✓ NavMenu component found in sidebar")
        else:
            print("✗ Sidebar element NOT found")
        
        # Check for main content
        main_content = soup.find('main') or soup.find(id='main-content')
        
        print("\n=== MAIN CONTENT STRUCTURE ===")
        if main_content:
            print("✓ Main content element found")
            main_id = main_content.get('id', '')
            print(f"  ID: {main_id}")
        else:
            print("✗ Main content element NOT found")
        
        # Check for page wrapper
        page = soup.find(class_='page') or soup.find(id='main-page')
        
        print("\n=== PAGE WRAPPER ===")
        if page:
            print("✓ Page wrapper found")
            page_classes = page.get('class', [])
            page_id = page.get('id', '')
            print(f"  Classes: {' '.join(page_classes)}")
            print(f"  ID: {page_id}")
        else:
            print("✗ Page wrapper NOT found")
        
        # Check for hamburger/toggle button
        hamburger = soup.find(class_='menu-toggle-btn') or soup.find(class_='navbar-toggler')
        
        print("\n=== HAMBURGER MENU ===")
        if hamburger:
            print("✓ Hamburger menu button found")
            print(f"  Classes: {' '.join(hamburger.get('class', []))}")
        else:
            # Try to find by icon
            bars_icon = soup.find('i', class_=re.compile('fa-bars'))
            if bars_icon:
                print("✓ Hamburger icon found (fa-bars)")
            else:
                print("✗ Hamburger menu NOT found")
        
        # Check CSS links
        print("\n=== CSS FILES ===")
        css_links = soup.find_all('link', rel='stylesheet')
        for link in css_links:
            href = link.get('href', '')
            if 'site.css' in href:
                print(f"✓ site.css loaded: {href}")
            elif 'viewscape.css' in href:
                print(f"✓ viewscape.css loaded: {href}")
            elif 'bootstrap' in href:
                print(f"✓ Bootstrap CSS loaded")
        
        # Check for logo
        print("\n=== LOGO ===")
        logo_img = soup.find('img', src=re.compile('f_symbol|fabos|logo'))
        if logo_img:
            print(f"✓ Logo image found: {logo_img.get('src', '')}")
            print(f"  Alt text: {logo_img.get('alt', '')}")
            
            # Check if logo is in sidebar
            logo_parent = logo_img.parent
            while logo_parent and logo_parent.name != 'body':
                if 'sidebar' in str(logo_parent.get('class', [])) or logo_parent.get('id') == 'main-sidebar':
                    print("✓ Logo is inside sidebar")
                    break
                logo_parent = logo_parent.parent
        else:
            print("✗ Logo image NOT found")
        
        # Extract inline styles if any
        print("\n=== INLINE STYLES ===")
        style_tags = soup.find_all('style')
        sidebar_styles_found = False
        for style in style_tags:
            style_text = style.string or ''
            if '.sidebar' in style_text or '#main-sidebar' in style_text:
                sidebar_styles_found = True
                # Extract sidebar-related styles
                sidebar_rules = re.findall(r'\.sidebar[^{]*\{[^}]*\}', style_text)
                if sidebar_rules:
                    print("Found sidebar styles in <style> tag:")
                    for rule in sidebar_rules[:3]:  # Show first 3 rules
                        print(f"  {rule[:100]}...")
        
        if not sidebar_styles_found:
            print("No inline sidebar styles found (styles in external CSS)")
        
        # Check Blazor components
        print("\n=== BLAZOR COMPONENTS ===")
        blazor_comments = soup.find_all(string=lambda text: isinstance(text, str) and 'Blazor:' in text)
        if blazor_comments:
            print(f"✓ Blazor server-side rendering detected ({len(blazor_comments)} markers)")
        
        blazor_script = soup.find('script', src=re.compile('blazor'))
        if blazor_script:
            print(f"✓ Blazor script loaded: {blazor_script.get('src', '')}")
        
        # Summary
        print("\n" + "=" * 60)
        print("LAYOUT VERIFICATION SUMMARY")
        print("=" * 60)
        
        checks = {
            "Sidebar element exists": sidebar is not None,
            "Main content element exists": main_content is not None,
            "Page wrapper exists": page is not None,
            "Hamburger menu exists": hamburger is not None or soup.find('i', class_=re.compile('fa-bars')) is not None,
            "Logo image exists": logo_img is not None,
            "site.css loaded": any('site.css' in link.get('href', '') for link in css_links),
            "Blazor configured": blazor_script is not None
        }
        
        passed = sum(checks.values())
        total = len(checks)
        
        for check, result in checks.items():
            status = "✓ PASS" if result else "✗ FAIL"
            print(f"{status}: {check}")
        
        print(f"\nResults: {passed}/{total} checks passed")
        
        if passed == total:
            print("\n✅ All layout checks passed! The sidebar should be properly positioned.")
        else:
            print("\n⚠️  Some checks failed. Review the layout configuration.")
        
        # Save the HTML for manual inspection
        with open('sidebar-test-output.html', 'w', encoding='utf-8') as f:
            f.write(response.text)
        print("\nHTML saved to sidebar-test-output.html for manual inspection")
        
    except requests.exceptions.RequestException as e:
        print(f"\n❌ Error connecting to application: {e}")
        print("Make sure the application is running on http://localhost:8080")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    test_sidebar_layout()