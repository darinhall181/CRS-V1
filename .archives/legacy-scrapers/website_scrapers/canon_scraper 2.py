import requests
from bs4 import BeautifulSoup
import pandas as pd
import json
import time
from urllib.parse import urljoin, urlparse
import re
from pathlib import Path
import xml.etree.ElementTree as ET
from playwright.sync_api import sync_playwright
from datetime import datetime
import argparse


'''This is a scraper for the Canon website. It is used to scrape the main canon shop page to find all the items on Canon's website currently for sale.'''

class CanonDataScraper:
    def __init__(self):
        self.base_url = "https://www.usa.canon.com/shop/" #general url used for canon website
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        })
        
        # Initialize Playwright for JavaScript-heavy sites
        self.playwright = None
        self.browser = None
        self.page = None

    def start_browser(self):
        """Start Playwright browser"""
        if not self.playwright:
            self.playwright = sync_playwright().start()
            # Use more realistic browser settings
            self.browser = self.playwright.chromium.launch(
                headless=False,  # Show browser for debugging
                args=[
                    '--no-sandbox',
                    '--disable-blink-features=AutomationControlled',
                    '--disable-dev-shm-usage',
                    '--disable-web-security',
                    '--disable-features=VizDisplayCompositor'
                ]
            )
            self.page = self.browser.new_page()
            
            # Set more realistic headers
            self.page.set_extra_http_headers({
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'none',
                'Cache-Control': 'max-age=0'
            })
            
            # Set viewport to look more realistic
            self.page.set_viewport_size({"width": 1920, "height": 1080})

    def stop_browser(self):
        """Stop Playwright browser"""
        if self.browser:
            self.browser.close()
        if self.playwright:
            self.playwright.stop()

    def find_body_pages(self):
        """Finds individual product pages for camera bodies using Playwright with Load More functionality"""
        camera_urls = []
        
        try:
            # Start browser
            self.start_browser()
            
            # Target specific Canon product pages
            target_urls = [
            #    "https://www.usa.canon.com/shop/digital-cameras",
            #    "https://www.usa.canon.com/shop/digital-cameras/mirrorless-cameras",
            #    "https://www.usa.canon.com/shop/digital-cameras/dslr-cameras",
            #    "https://www.usa.canon.com/shop/digital-cameras/point-and-shoot-cameras",
            #    "https://www.usa.canon.com/shop/pro/cameras/ptz-remote-cameras",
            #    "https://www.usa.canon.com/shop/pro/cameras/cinema-cameras",
            #    "https://www.usa.canon.com/shop/pro/cameras/multi-purpose-cameras",
            #    "https://www.usa.canon.com/shop/pro/cameras/pro-camcorders",
            #    "https://www.usa.canon.com/shop/digital-cameras/camera-accessories"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=30)  # Increased from 3 to 30
                    camera_urls.extend(new_urls)
                    
                    print(f"  Found {len(new_urls)} products on {target_url}")
                    
                    # Debug: Print first few links found
                    if new_urls:
                        print(f"  Sample URLs: {new_urls[:3]}")
                        
                    # Continue to next target URL to scan all pages
                        
                except Exception as e:
                    print(f"Error accessing {target_url}: {e}")
                    continue
            
            unique_urls = list(set(camera_urls))
            print(f"\n📊 Pagination Summary:")
            print(f"  Total unique products found: {len(unique_urls)}")
            print(f"  Returning all products for HTML saving")
            return unique_urls  # Return all unique URLs
            
        except Exception as e:
            print(f"Error in find_body_pages: {e}")
            return []

    def _extract_product_links(self, soup, base_url):
        """Extract product URLs from page HTML"""
        product_urls = []
        
        # Debug counter
        total_links_checked = 0
        product_links_found = 0
        
        # Look for links with class "product-item-link"
        product_links = soup.find_all('a', class_='product-item-link')
        total_links_checked += len(product_links)
        
        for link in product_links:
            href = link.get('href')
            if href:
                # Make sure it's a full URL
                if href.startswith('/'):
                    full_url = urljoin(base_url, href)
                else:
                    full_url = href
                # Only include actual product pages (not filter pages) and exclude refurbished
                if '/shop/p/' in full_url and '?' not in full_url and 'refurbished' not in full_url.lower():
                    product_urls.append(full_url)
                    product_links_found += 1
        
        # Also look for any links that contain the product pattern
        all_links = soup.find_all('a', href=True)
        total_links_checked += len(all_links)
        
        for link in all_links:
            href = link.get('href')
            if href and ('/shop/p/' in href or href.startswith('/shop/p/')):
                # Make sure it's a full URL
                if href.startswith('/'):
                    full_url = urljoin(base_url, href)
                else:
                    full_url = href
                # Only include actual product pages (not filter pages) and exclude refurbished
                if '/shop/p/' in full_url and '?' not in full_url and 'refurbished' not in full_url.lower() and full_url not in product_urls:
                    product_urls.append(full_url)
                    product_links_found += 1
        
        # Look for product links in different formats
        product_selectors = [
            'a[href*="/shop/p/"]',
            'a[class*="product"]',
            'a[class*="item"]'
        ]
        
        for selector in product_selectors:
            links = soup.select(selector)
            total_links_checked += len(links)
            
            for link in links:
                href = link.get('href')
                if href:
                    if href.startswith('/'):
                        full_url = urljoin(base_url, href)
                    else:
                        full_url = href
                    # Only include actual product pages (not filter pages) and exclude refurbished
                    if '/shop/p/' in full_url and '?' not in full_url and 'refurbished' not in full_url.lower() and full_url not in product_urls:
                        product_urls.append(full_url)
                        product_links_found += 1
        
        # Debug output
        print(f"    🔍 Extracted {product_links_found} product links from {total_links_checked} total links checked")
        
        return product_urls

    def save_product_html(self, url, company="canon", category="body", max_retries=3):
        """Save the HTML of a product page to a local file with retry logic and bot detection avoidance"""
        # Normalize away fragments (e.g. #toreviews)
        url = (url or "").split("#")[0]
        for attempt in range(max_retries):
            try:
                # Create output directory if it doesn't exist
                base_dir = Path("data/company_product")
                output_dir = base_dir / company / "raw_html"
                output_dir.mkdir(parents=True, exist_ok=True)
                
                # Use Playwright to get the page
                if not self.page:
                    self.start_browser()
                
                print(f"Saving HTML from: {url} (attempt {attempt + 1}/{max_retries})")
                
                # Navigate to the page
                self.page.goto(url, wait_until='domcontentloaded', timeout=30000)
                time.sleep(2)  # Wait for content to load
                
                # Get the page content
                page_content = self.page.content()
                
                # Check if the page contains "Access Denied"
                if "Access Denied" in page_content:
                    print(f"  ⚠️  Access denied for: {url}")
                    return None
                
                # Extract filename from URL
                filename = url.split('/')[-1].split('#')[0]  # Remove any fragment
                if not filename.endswith('.html'):
                    filename += '.html'
                
                filepath = Path(output_dir) / filename
                
                # Check if file exists and if it contains "Access Denied"
                should_overwrite = False
                if filepath.exists():
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            existing_content = f.read()
                            if "<title>Access Denied</title>" in existing_content:
                                print(f"  🔄 File exists but contains 'Access Denied', re-scraping: {filepath}")
                                should_overwrite = True
                            else:
                                print(f"  ⚠️  File already exists, skipping: {filepath}")
                                return str(filepath)
                    except Exception as e:
                        print(f"  ⚠️  Error reading existing file, will overwrite: {e}")
                        should_overwrite = True
                
                # Save the HTML content
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(page_content)
                
                print(f"  ✅ Saved: {filepath}")
                return str(filepath)
                
            except Exception as e:
                print(f"  ❌ Error saving {url}: {e}")
                if attempt < max_retries - 1:
                    print(f"  🔄 Retrying... ({attempt + 1}/{max_retries})")
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    print(f"  ❌ Failed to save {url} after {max_retries} attempts")
                    return None
        
        return None

    def load_url_inventory(self, inventory_path: str):
        """
        Load URLs from the spec_pipeline discovery JSON file, e.g.:
          data/url_lists/canon_camera_urls.json

        Returns:
          (urls, metadata_dict)
        """
        p = Path(inventory_path)
        if not p.exists():
            raise FileNotFoundError(f"URL inventory not found: {inventory_path}")
        data = json.loads(p.read_text(encoding="utf-8"))
        urls = data.get("urls", [])
        return urls, data

    def find_url_by_slug(self, urls, slug: str):
        """
        Find a URL whose last path segment equals `slug`.
        """
        target = (slug or "").strip().lower()
        for u in urls:
            try:
                u_norm = (u or "").split("#")[0]
                path_slug = (urlparse(u_norm).path or "").rstrip("/").split("/")[-1].lower()
                if path_slug == target:
                    return u_norm
            except Exception:
                continue
        return None

    def save_all_product_html(self, urls, company="canon", category="body", start_from_index=0):
        """Save HTML for all product URLs with better tracking and bot detection avoidance"""
        base_dir = Path("data/company_product")
        saved_files = []
        failed_urls = []
        
        try:
            # Start browser once for all pages
            self.start_browser()
            
            # Filter URLs to start from the specified index
            urls_to_process = urls[start_from_index:]
            print(f"📊 Starting from URL index {start_from_index} (processing {len(urls_to_process)} URLs)")
            
            for i, url in enumerate(urls_to_process, start_from_index + 1):
                print(f"\nProcessing {i}/{len(urls)}: {url}")
                
                # Add random delay between requests (2-5 seconds)
                import random
                delay = random.uniform(2, 5)
                print(f"  ⏱️  Waiting {delay:.1f} seconds...")
                time.sleep(delay)
                
                saved_file = self.save_product_html(url, company, category)
                if saved_file:
                    saved_files.append(saved_file)
                else:
                    failed_urls.append(url)
                
                # Add longer delay every 10 requests to avoid detection
                if i % 10 == 0:
                    long_delay = random.uniform(8, 12)
                    print(f"  🛑 Taking a longer break ({long_delay:.1f}s) to avoid detection...")
                    time.sleep(long_delay)
                
                # Add even longer delay every 50 requests
                if i % 50 == 0:
                    very_long_delay = random.uniform(15, 25)
                    print(f"  🛑 Taking a much longer break ({very_long_delay:.1f}s) to avoid detection...")
                    time.sleep(very_long_delay)
            
            unique_files = list(set(saved_files))
            actual_files_count = len([f for f in unique_files if f is not None])
            
            print(f"\n📊 Summary:")
            print(f"  ✅ Successfully processed: {len(saved_files)} URLs")
            print(f"  📁 Unique files saved: {actual_files_count} files")
            print(f"  ❌ Failed to save: {len(failed_urls)} files")
            print(f"  📁 Location: {base_dir}/{company}/raw_html/")
            
            # Show duplicate info if there are duplicates
            if len(saved_files) > actual_files_count:
                print(f"  ⚠️  Duplicates removed: {len(saved_files) - actual_files_count} files")

            if failed_urls:
                print(f"\n❌ Failed URLs:")
                for url in failed_urls:
                    print(f"  - {url}")
            
            return saved_files
            
        except Exception as e:
            print(f"Error in save_all_product_html: {e}")
            return saved_files
        finally:
            self.stop_browser()


    def _scrape_with_load_more(self, url, max_load_more=10):
        """Scrape product URLs from a page with comprehensive pagination checking"""
        product_urls = []
        initial_count = 0
        url_pagination_count = 0
        button_pagination_count = 0
        
        try:
            # Start browser if not already started
            if not self.page:
                self.start_browser()
            
            print(f"🌐 Navigating to: {url}")
            self.page.goto(url, wait_until='domcontentloaded', timeout=30000)
            time.sleep(3)  # Wait for content to load
            
            # Get initial page content
            page_content = self.page.content()
            soup = BeautifulSoup(page_content, 'html.parser')
            
            # Extract product links from initial page
            initial_products = self._extract_product_links(soup, url)
            product_urls.extend(initial_products)
            initial_count = len(initial_products)
            print(f"  📦 Found {initial_count} products on initial page")
            
            # First, try URL-based pagination (more reliable)
            print(f"  🔗 Checking URL-based pagination...")
            url_pagination_products = self._scrape_url_pagination(url, max_pages=max_load_more)
            if url_pagination_products:
                product_urls.extend(url_pagination_products)
                url_pagination_count = len(url_pagination_products)
                print(f"  📄 Found {url_pagination_count} additional products via URL pagination")
            
            # Only try button-based pagination if URL pagination didn't find many products
            # This serves as a backup for sites that don't use URL pagination
            if url_pagination_count < 10:  # If URL pagination found less than 10 products, try button pagination
                print(f"  🔘 URL pagination found few products ({url_pagination_count}), trying button pagination as backup...")
                button_pagination_products = self._scrape_button_pagination(url, max_load_more)
                if button_pagination_products:
                    # Only add products not already found
                    new_products = [p for p in button_pagination_products if p not in product_urls]
                    product_urls.extend(new_products)
                    button_pagination_count = len(new_products)
                    print(f"  🔘 Found {button_pagination_count} additional products via button pagination")
            else:
                print(f"  🔘 Skipping button pagination - URL pagination found sufficient products ({url_pagination_count})")
            
            # Final summary
            print(f"  📊 Final Summary:")
            print(f"    Initial page: {initial_count} products")
            print(f"    URL pagination: {url_pagination_count} products")
            print(f"    Button pagination: {button_pagination_count} products")
            print(f"    Total unique products found: {len(product_urls)}")
            
        except Exception as e:
            print(f"Error in _scrape_with_load_more: {e}")
        
        return product_urls

    def _scrape_url_pagination(self, base_url, max_pages=30):
        """Scrape products using URL-based pagination (?p=2, ?p=3, etc.)"""
        all_products = []
        pages_checked = 0
        pages_with_products = 0
        consecutive_empty_pages = 0
        
        try:
            print(f"    📄 Starting URL pagination (max_pages={max_pages})")
            
            for page_num in range(2, max_pages + 2):  # Start from page 2 (page 1 is base_url)
                page_url = f"{base_url}?p={page_num}"
                pages_checked += 1
                
                print(f"    📄 Checking page {page_num}: {page_url}")
                
                try:
                    # Navigate to the page
                    self.page.goto(page_url, wait_until='domcontentloaded', timeout=20000)
                    time.sleep(2)
                    
                    # Get page content
                    page_content = self.page.content()
                    soup = BeautifulSoup(page_content, 'html.parser')
                    
                    # Check if page has products (not a 404 or empty page)
                    products_on_page = self._extract_product_links(soup, page_url)
                    
                    if products_on_page:
                        all_products.extend(products_on_page)
                        pages_with_products += 1
                        consecutive_empty_pages = 0  # Reset counter
                        print(f"      ✅ Found {len(products_on_page)} products on page {page_num} (total: {len(all_products)})")
                    else:
                        consecutive_empty_pages += 1
                        print(f"      ⚠️  No products found on page {page_num} (consecutive empty: {consecutive_empty_pages})")
                        
                        # Stop if we've had 3 consecutive empty pages
                        if consecutive_empty_pages >= 3:
                            print(f"      🛑 Stopping pagination after {consecutive_empty_pages} consecutive empty pages")
                            break
                        
                except Exception as e:
                    consecutive_empty_pages += 1
                    print(f"      ❌ Error accessing page {page_num}: {e}")
                    
                    # Stop if we've had 3 consecutive errors
                    if consecutive_empty_pages >= 3:
                        print(f"      🛑 Stopping pagination after {consecutive_empty_pages} consecutive errors")
                        break
                    
                    continue
            
            print(f"    📊 URL Pagination Summary:")
            print(f"      Pages checked: {pages_checked}")
            print(f"      Pages with products: {pages_with_products}")
            print(f"      Total products found: {len(all_products)}")
                    
        except Exception as e:
            print(f"Error in _scrape_url_pagination: {e}")
        
        return all_products

    def _scrape_button_pagination(self, url, max_clicks=5):
        """Scrape products using button-based pagination (Load More button)"""
        all_products = []
        initial_count = 0
        new_products_per_click = []
        
        try:
            # Navigate to the base URL
            self.page.goto(url, wait_until='domcontentloaded', timeout=30000)
            time.sleep(3)
            
            # Get initial page content
            page_content = self.page.content()
            soup = BeautifulSoup(page_content, 'html.parser')
            
            # Extract initial products
            initial_products = self._extract_product_links(soup, url)
            all_products.extend(initial_products)
            initial_count = len(initial_products)
            print(f"    📦 Initial page: {initial_count} products")
            
            # Look for and handle "Load More" button
            load_more_count = 0
            while load_more_count < max_clicks:
                # Find "Load More" button using Playwright
                load_more_button = self._find_load_more_button_playwright()
                
                if not load_more_button:
                    print(f"    🔍 No more 'Load More' button found after {load_more_count} clicks")
                    break
                
                # Click "Load More" button
                print(f"    🔘 Clicking 'Load More' button (attempt {load_more_count + 1}/{max_clicks})")
                try:
                    load_more_button.click()
                    time.sleep(3)  # Wait for new content to load
                    
                    # Get updated page content
                    page_content = self.page.content()
                    soup = BeautifulSoup(page_content, 'html.parser')
                    
                    # Extract new product links
                    all_current_products = self._extract_product_links(soup, url)
                    new_products = [p for p in all_current_products if p not in all_products]
                    
                    if new_products:
                        all_products.extend(new_products)
                        new_products_per_click.append(len(new_products))
                        print(f"      ✅ Loaded {len(new_products)} more products (total: {len(all_products)})")
                        load_more_count += 1
                        time.sleep(2)  # Be respectful
                    else:
                        print(f"      ⚠️  No new products loaded after click")
                        break
                        
                except Exception as e:
                    print(f"      ❌ Error clicking 'Load More' button: {e}")
                    break
            
            # Summary
            print(f"    📊 Button Pagination Summary:")
            print(f"      Initial products: {initial_count}")
            print(f"      Load more clicks: {load_more_count}")
            print(f"      New products per click: {new_products_per_click}")
            print(f"      Total products: {len(all_products)}")
                    
        except Exception as e:
            print(f"Error in _scrape_button_pagination: {e}")
        
        return all_products

    def _find_load_more_button_playwright(self):
        """Find 'Load More' button using Playwright"""
        try:
            # Canon-specific selectors for "Load More" buttons
            load_more_selectors = [
                'button[class*="amscroll-load-button"]',  # Canon's specific class
                'button[class*="load-more"]',
                'button[class*="loadmore"]',
                'button:has-text("Load more")',
                'button:has-text("Load More")',
                '[class*="amscroll"]:has-text("Load more")',
                '[class*="amscroll"]:has-text("Load More")'
            ]
            
            for selector in load_more_selectors:
                try:
                    button = self.page.query_selector(selector)
                    if button:
                        # Check if button is visible and clickable
                        if button.is_visible() and button.is_enabled():
                            return button
                except:
                    continue
            
            # Also look for buttons with "Load More" text using text content
            buttons = self.page.query_selector_all('button')
            for button in buttons:
                try:
                    text = button.text_content().lower()
                    if 'load more' in text and button.is_visible() and button.is_enabled():
                        return button
                except:
                    continue
            
            return None
            
        except Exception as e:
            print(f"Error finding load more button: {e}")
            return None


    def test_canon_access(self):
        """Test if we can access Canon's main site"""
        try:
            # Start browser
            self.start_browser()
            
            # Try the main Canon site first
            print("Testing access to main Canon site...")
            self.page.goto("https://www.usa.canon.com", wait_until='domcontentloaded', timeout=30000)  # Reduced timeout
            time.sleep(3)
            
            page_content = self.page.content()
            soup = BeautifulSoup(page_content, 'html.parser')
            
            print(f"Page title: {soup.title.string if soup.title else 'No title'}")
            print(f"Total links: {len(soup.find_all('a'))}")
            
            # Look for any shop links
            shop_links = soup.find_all('a', href=True)
            shop_urls = [link.get('href') for link in shop_links if 'shop' in link.get('href', '').lower()]
            print(f"Shop links found: {shop_urls[:5]}")
            
            return len(shop_urls) > 0
            
        except Exception as e:
            print(f"Error testing Canon access: {e}")
            return False


    def find_lens_pages(self):
        """Finds individual product pages for camera lenses using Playwright with Load More functionality"""
        lens_urls = []
        
        try:
            # Start browser
            self.start_browser()
            
            # Target specific Canon lens pages
            target_urls = [
            #    "https://www.usa.canon.com/shop/camera-lenses",
            #    "https://www.usa.canon.com/shop/lenses/ef-lenses",
            #    "https://www.usa.canon.com/shop/lenses/rf-lenses",
            #    "https://www.usa.canon.com/shop/lenses/ef-s-lenses",
            #    "https://www.usa.canon.com/shop/lenses/lenses",
            #    "https://www.usa.canon.com/shop/pro/lenses/cinema-lenses",
            #    "https://www.usa.canon.com/shop/pro/lenses/broadcast-lenses",
            #     "https://www.usa.canon.com/shop/pro/lenses/lens-accessories"
            #     "https://www.usa.canon.com/shop/pro/lenses"
                 "https://www.usa.canon.com/shop/pro/lenses/broadcast-lenses"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=30)  # Increased from 5 to 30
                    lens_urls.extend(new_urls)
                    
                    print(f"  Found {len(new_urls)} products on {target_url}")
                    
                    # Debug: Print first few links found
                    if new_urls:
                        print(f"  Sample URLs: {new_urls[:3]}")
                        
                    if lens_urls:  # If we found URLs, we can stop
                        break
                        
                except Exception as e:
                    print(f"Error accessing {target_url}: {e}")
                    continue
            
            unique_urls = list(set(lens_urls))
            print(f"\n📊 Lens Pagination Summary:")
            print(f"  Total unique lens products found: {len(unique_urls)}")
            print(f"  Returning all products for HTML saving")
            return unique_urls  # Return all unique URLs
            
        except Exception as e:
            print(f"Error in find_lens_pages: {e}")
            return []

    def find_video_pages(self):
        """Finds individual product pages for video cameras using Playwright with Load More functionality"""
        video_urls = []
        
        try:
            # Start browser
            self.start_browser()
            
            # Target specific Canon video camera pages
            target_urls = [
                "https://www.usa.canon.com/shop/video-cameras",
                "https://www.usa.canon.com/shop/pro/cameras/cinema-cameras"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=30)  # Increased from 3 to 30
                    video_urls.extend(new_urls)
                    
                    print(f"  Found {len(new_urls)} products on {target_url}")
                    
                    # Debug: Print first few links found
                    if new_urls:
                        print(f"  Sample URLs: {new_urls[:3]}")
                    else:
                        print(f"  ❌ No URLs found on {target_url}")
                        print(f"  DEBUG: Let's check if the page loads correctly...")
                        
                        # Try to load the page and see what we get
                        try:
                            self.page.goto(target_url, wait_until='networkidle')
                            time.sleep(3)
                            page_content = self.page.content()
                            soup = BeautifulSoup(page_content, 'html.parser')
                            
                            # Look for any product links
                            all_links = soup.find_all('a', href=True)
                            product_links = [link for link in all_links if '/shop/p/' in link.get('href', '')]
                            print(f"  DEBUG: Found {len(product_links)} potential product links on page")
                            
                            if product_links:
                                print(f"  DEBUG: Sample product links: {[link.get('href') for link in product_links[:3]]}")
                            
                        except Exception as debug_e:
                            print(f"  DEBUG: Error checking page content: {debug_e}")
                        
                except Exception as e:
                    print(f"Error accessing {target_url}: {e}")
                    continue
            
            unique_urls = list(set(video_urls))
            print(f"\n📊 Video Camera Pagination Summary:")
            print(f"  Total unique video camera products found: {len(unique_urls)}")
            print(f"  Returning all products for HTML saving")
            return unique_urls  # Return all unique URLs
            
        except Exception as e:
            print(f"Error in find_video_pages: {e}")
            return []

    def scrape_website_specs(self, url):
        """Scrape camera specifications from Canon website using Playwright"""
        try:
            # Use Playwright instead of requests to avoid 403 errors
            if not self.page:
                self.start_browser()
            
            print(f"Scraping specs from: {url}")
            self.page.goto(url, wait_until='networkidle')
            time.sleep(2)  # Wait for content to load
            
            page_content = self.page.content()
            soup = BeautifulSoup(page_content, 'html.parser')
            
            # Extract basic info
            product_data = {
                'url': url,
                'title': '',
                'model': '',
                'type': '',
                'specifications': {},
                'images': [],
                'price': '',
                'description': ''
            }
            
            # Finding the title of the product
            title_selectors = ['h1', '.product-title', '.page-title', 'title', '.product-item-name']
            for selector in title_selectors:
                title_elem = soup.select_one(selector)
                if title_elem:
                    product_data['title'] = title_elem.get_text().strip()
                    break

            # Look for specifications tables/sections
            spec_sections = soup.find_all(['table', 'div'], class_=re.compile(r'spec|specification|feature|detail', re.I))
            
            for section in spec_sections:
                # Extract table data
                rows = section.find_all('tr')
                for row in rows:
                    cells = row.find_all(['td', 'th'])
                    if len(cells) >= 2:
                        key = cells[0].get_text().strip()
                        value = cells[1].get_text().strip()
                        if key and value:
                            product_data['specifications'][key] = value
                
                # Extract list data
                items = section.find_all('li')
                for item in items:
                    text = item.get_text().strip()
                    if ':' in text:
                        key, value = text.split(':', 1)
                        product_data['specifications'][key.strip()] = value.strip()
            
            # Look for images
            img_tags = soup.find_all('img', src=True)
            for img in img_tags:
                src = img['src']
                if src and not src.startswith('data:'):
                    full_url = urljoin(url, src)
                    product_data['images'].append(full_url)
            
            # Look for price
            price_selectors = ['.price', '.cost', '[class*="price"]', '[class*="cost"]']
            for selector in price_selectors:
                price_elem = soup.select_one(selector)
                if price_elem:
                    product_data['price'] = price_elem.get_text().strip()
                    break
            
            # Extract description
            desc_selectors = ['.description', '.overview', '.product-description', 'p']
            for selector in desc_selectors:
                desc_elem = soup.select_one(selector)
                if desc_elem and len(desc_elem.get_text().strip()) > 50:
                    product_data['description'] = desc_elem.get_text().strip()[:500]
                    break

            return product_data
            
        except Exception as e:
            print(f"Error scraping {url}: {e}")
            return None

    def save_urls_to_json(self, urls, company="canon", category="body"):
        """Save discovered URLs to a JSON file for later use"""
        import json
        from pathlib import Path
        
        # Create data directory if it doesn't exist
        data_dir = Path("data/url_lists")
        data_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"{company}_{category}_urls.json"
        filepath = data_dir / filename
        
        # Save URLs with metadata
        data = {
            "company": company,
            "category": category,
            "total_urls": len(urls),
            "discovery_date": str(datetime.now()),
            "urls": urls
        }
        
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"📄 Saved {len(urls)} URLs to: {filepath}")
        return filepath
    
    def load_urls_from_json(self, company="canon", category="body"):
        """Load URLs from JSON file"""
        import json
        from pathlib import Path
        
        filename = f"{company}_{category}_urls.json"
        filepath = Path("data/url_lists") / filename
        
        if not filepath.exists():
            print(f"❌ URL file not found: {filepath}")
            return None
        
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        print(f"📄 Loaded {len(data['urls'])} URLs from: {filepath}")
        return data['urls']
    
    def scrape_in_batches(self, urls, company="canon", category="body", batch_size=120, start_index=0):
        """Scrape URLs in batches to avoid bot detection"""
        total_urls = len(urls)
        end_index = min(start_index + batch_size, total_urls)
        
        print(f"📊 Batch processing: URLs {start_index + 1}-{end_index} of {total_urls}")
        print(f"📊 Processing {end_index - start_index} URLs in this batch")
        
        # Get the batch of URLs to process
        batch_urls = urls[start_index:end_index]
        
        # Save HTML files for this batch
        saved_files = self.save_all_product_html(batch_urls, company, category)
        
        print(f"✅ Batch complete: {len(saved_files)} files saved")
        print(f"📊 Next batch would start at index: {end_index}")
        
        return saved_files, end_index



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Canon scraper utilities")
    parser.add_argument("--url-inventory", default="data/url_lists/canon_camera_urls.json")
    parser.add_argument("--slug", default="eos-r6-mark-iii")
    parser.add_argument("--company", default="canon")
    parser.add_argument("--category", default="camera")
    parser.add_argument("--max-retries", type=int, default=3)
    args = parser.parse_args()

    scraper = CanonDataScraper()
    try:
        urls, meta = scraper.load_url_inventory(args.url_inventory)
        target_url = scraper.find_url_by_slug(urls, args.slug)
        if not target_url:
            raise ValueError(f"Slug not found in inventory: {args.slug}")

        print(f"Found URL for slug '{args.slug}': {target_url}")
        saved = scraper.save_product_html(
            target_url,
            company=args.company,
            category=args.category,
            max_retries=args.max_retries,
        )
        print(f"Saved HTML: {saved}")
    finally:
        scraper.stop_browser()