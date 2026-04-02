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


'''This is a scraper for the Sony website. It is used to scrape the main sony shop page to find all the items on Sony's website currently for sale.'''

class SonyDataScraper:
    def __init__(self):
        self.base_url = "https://electronics.sony.com/" #general url used for sony website
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
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
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
            
            # Target specific Sony product pages
            target_urls = [
            #    "https://electronics.sony.com/imaging/interchangeable-lens-cameras/c/all-interchangeable-lens-cameras"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=30) 
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
    
    def _scrape_with_load_more(self, url, max_load_more):
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
            self.page.goto(url, wait_until='networkidle', timeout=30000)
            time.sleep(8)  # Wait for content to load
            
            # Wait for product elements to be visible (more robust)
            try:
                self.page.wait_for_selector('a[href*="/p/"]', timeout=10000)
                print(f"  ✅ Product links detected on page")
            except:
                print(f"  ⚠️  No product links detected with selector, proceeding anyway")
            
            # Debug: Check for "Load More" or pagination buttons
            try:
                load_more_buttons = self.page.query_selector_all('button:has-text("Load More"), button:has-text("Show More"), [class*="load"], [class*="pagination"]')
                print(f"  🔍 Found {len(load_more_buttons)} potential load more/pagination elements")
                
                # Also check for any buttons with "more" text
                all_buttons = self.page.query_selector_all('button')
                more_buttons = [btn for btn in all_buttons if 'more' in btn.text_content().lower()]
                print(f"  🔍 Found {len(more_buttons)} buttons containing 'more' text")
                
            except Exception as e:
                print(f"  ⚠️  Error checking for load more buttons: {e}")
            
            # Get initial page content
            page_content = self.page.content()
            soup = BeautifulSoup(page_content, 'html.parser')

            # Extract product links from initial page
            initial_products = self._extract_product_links(soup, url)
            product_urls.extend(initial_products)
            initial_count = len(initial_products)
            print(f"  📦 Found {initial_count} products on initial page")
            
            # Debug: Check total number of /p/ links in HTML
            all_p_links = soup.find_all('a', href=lambda x: x and '/p/' in x)
            print(f"  🔍 DEBUG: Total /p/ links found in HTML: {len(all_p_links)}")
            
            # Debug: Check for the specific custom-product-grid-item__info class
            custom_product_items = soup.find_all(class_='custom-product-grid-item__info')
            print(f"  🔍 DEBUG: Found {len(custom_product_items)} custom-product-grid-item__info elements")
            
            # Debug: Check for /imaging/lenses/ links specifically
            lens_links = soup.find_all('a', href=lambda x: x and '/imaging/lenses/' in x)
            print(f"  🔍 DEBUG: Found {len(lens_links)} /imaging/lenses/ links")
            
            # Debug: Show some sample /p/ links
            if all_p_links:
                print(f"  📋 Sample /p/ links found:")
                for i, link in enumerate(all_p_links[:5]):
                    href = link.get('href', '')
                    print(f"    {i+1}. {href}")
            
            # Debug: Show some sample /imaging/lenses/ links
            if lens_links:
                print(f"  📋 Sample /imaging/lenses/ links found:")
                for i, link in enumerate(lens_links[:5]):
                    href = link.get('href', '')
                    print(f"    {i+1}. {href}")
            
            # First, try URL-based pagination (more reliable)
            print(f"  🔗 Checking URL-based pagination...")
            url_pagination_products = self._scrape_url_pagination(url, max_pages=max_load_more)
            if url_pagination_products:
                # Only add products not already found to avoid duplicates
                new_products = [p for p in url_pagination_products if p not in product_urls]
                product_urls.extend(new_products)
                url_pagination_count = len(new_products)
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
    
    def _scrape_url_pagination(self, base_url, max_pages=10):
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
                    self.page.goto(page_url, wait_until='networkidle', timeout=20000)
                    time.sleep(5)
                    
                    # Get page content
                    page_content = self.page.content()
                    soup = BeautifulSoup(page_content, 'html.parser')
                    
                    # Check if page has products (not a 404 or empty page)
                    products_on_page = self._extract_product_links(soup, page_url)
                    if products_on_page:
                        # Only add products not already found to avoid duplicates
                        new_products = [p for p in products_on_page if p not in all_products]
                        all_products.extend(new_products)
                        pages_with_products += 1
                        print(f"      ✅ Found {len(products_on_page)} products on page {page_num}, {len(new_products)} new (total: {len(all_products)})")
                        
                        # Check if we found new products or just duplicates
                        if len(new_products) == 0 and len(products_on_page) > 0:
                            print(f"      🔍 DEBUG: All {len(products_on_page)} products were duplicates. Sample: {products_on_page[:2]}")
                            consecutive_empty_pages += 1
                            # Stop if we've had 2 consecutive pages with only duplicates
                            if consecutive_empty_pages >= 5:
                                print(f"      🛑 Stopping pagination after {consecutive_empty_pages} consecutive pages with only duplicates")
                                break
                        else:
                            consecutive_empty_pages = 0  # Reset counter only if we found new products
                    else:
                        consecutive_empty_pages += 1
                        print(f"      ⚠️  No products found on page {page_num} (consecutive empty: {consecutive_empty_pages})")
                        
                        # Stop if we've had 3 consecutive empty pages
                        if consecutive_empty_pages >= 5:
                            print(f"      🛑 Stopping pagination after {consecutive_empty_pages} consecutive empty pages")
                            break
                        
                except Exception as e:
                    consecutive_empty_pages += 1
                    print(f"      ❌ Error accessing page {page_num}: {e}")
                    
                    # Stop if we've had 3 consecutive errors
                    if consecutive_empty_pages >= 5:
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
            self.page.goto(url, wait_until='networkidle', timeout=30000)
            time.sleep(5)
            
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

    def _extract_product_links(self, soup, base_url):
        """Extract product URLs from page HTML"""
        product_urls = []
        
        # Debug counter
        total_links_checked = 0
        product_links_found = 0
        
        # Sony base URL for constructing full URLs
        sony_base = "https://electronics.sony.com"
        
        # Look for Sony-specific product link patterns, focusing on the custom-product-grid-item__info class
        product_selectors = [
            '.custom-product-grid-item__info a[href*="/p/"]',  # Target the specific class you mentioned
            'a[href*="/imaging/lenses/"]',  # Sony lens product links
            'a[href*="/p/"]',  # Sony uses /p/ for product pages
            'a[class*="product"]',
            'a[class*="item"]',
            'a[class*="card"]'
        ]
        
        for selector in product_selectors:
            links = soup.select(selector)
            total_links_checked += len(links)
            
            for link in links:
                href = link.get('href')
                if href:
                    # Convert relative URLs to full URLs
                    if href.startswith('/'):
                        full_url = sony_base + href
                    elif href.startswith('http'):
                        full_url = href
                    else:
                        full_url = urljoin(sony_base, href)
                    
                    # Only include actual product pages (not filter pages)
                    if '/p/' in full_url and '?' not in full_url and full_url not in product_urls:
                        product_urls.append(full_url)
                        product_links_found += 1
        
        # Also look for any links that contain the product pattern in the entire page
        all_links = soup.find_all('a', href=True)
        total_links_checked += len(all_links)
        
        for link in all_links:
            href = link.get('href')
            if href and ('/p/' in href or href.startswith('/p/') or '/imaging/lenses/' in href):
                # Convert relative URLs to full URLs
                if href.startswith('/'):
                    full_url = sony_base + href
                elif href.startswith('http'):
                    full_url = href
                else:
                    full_url = urljoin(sony_base, href)
                
                # Only include actual product pages (not filter pages)
                if '/p/' in full_url and '?' not in full_url and full_url not in product_urls:
                    product_urls.append(full_url)
                    product_links_found += 1
        
        # Debug output
        print(f"    🔍 Extracted {product_links_found} product links from {total_links_checked} total links checked")
        
        # Additional debugging - show sample URLs found
        if product_urls:
            print(f"    📋 Sample product URLs found:")
            for i, url in enumerate(product_urls[:5]):
                print(f"      {i+1}. {url}")
        
        return product_urls

    def _find_load_more_button_playwright(self):
        """Find 'Load More' button using Playwright"""
        try:
            # Sony-specific selectors for "Load More" buttons
            load_more_selectors = [
                'button[class*="load-more"]',
                'button[class*="loadmore"]',
                'button:has-text("Load more")',
                'button:has-text("Load More")',
                'button:has-text("Show more")',
                'button:has-text("Show More")',
                '[class*="load"]:has-text("Load more")',
                '[class*="load"]:has-text("Load More")'
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
                    if ('load more' in text or 'show more' in text) and button.is_visible() and button.is_enabled():
                        return button
                except:
                    continue
            
            return None
            
        except Exception as e:
            print(f"Error finding load more button: {e}")
            return None

    def save_product_html(self, url, company="sony", category="body", max_retries=3):
        """Save the HTML of a product page to a local file with retry logic and bot detection avoidance"""
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

    def save_all_product_html(self, urls, company="sony", category="body", start_from_index=0):
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

    def find_lens_pages(self):
        """Finds individual product pages for camera lenses using Playwright with Load More functionality"""
        lens_urls = []
        
        try:
            # Start browser
            self.start_browser()
            
            # Target specific Sony lens pages
            target_urls = [
                "https://electronics.sony.com/imaging/c/lenses"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=30)
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

    def find_compact_cameras(self):
        """Finds individual product pages for compact cameras using Playwright with Load More functionality"""
        compact_urls = []
        
        try:
            # Start browser
            self.start_browser()
            
            # Target specific Sony compact camera pages
            target_urls = [
                "https://electronics.sony.com/c/all-vlog-compact-cameras"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=30)
                    compact_urls.extend(new_urls)
                    
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
                            product_links = [link for link in all_links if '/p/' in link.get('href', '')]
                            print(f"  DEBUG: Found {len(product_links)} potential product links on page")
                            
                            if product_links:
                                print(f"  DEBUG: Sample product links: {[link.get('href') for link in product_links[:3]]}")
                            
                        except Exception as debug_e:
                            print(f"  DEBUG: Error checking page content: {debug_e}")
                        
                except Exception as e:
                    print(f"Error accessing {target_url}: {e}")
                    continue
            
            unique_urls = list(set(compact_urls))
            print(f"\n📊 Compact Camera Pagination Summary:")
            print(f"  Total unique compact camera products found: {len(unique_urls)}")
            print(f"  Returning all products for HTML saving")
            return unique_urls  # Return all unique URLs
            
        except Exception as e:
            print(f"Error in find_compact_cameras: {e}")
            return []

    def find_camcorders(self):
        """Finds individual product pages for camcorders using Playwright with Load More functionality"""
        camcorder_urls = []
        
        try:
            # Start browser
            self.start_browser()
            
            # Target specific Sony camcorder pages
            target_urls = [
                "https://electronics.sony.com/c/all-camcorders"
            ]

            for target_url in target_urls:
                try:
                    print(f"Scraping from: {target_url}")
                    
                    # Use the new _scrape_with_load_more method that handles pagination
                    new_urls = self._scrape_with_load_more(target_url, max_load_more=3)
                    camcorder_urls.extend(new_urls)
                    
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
                            product_links = [link for link in all_links if '/p/' in link.get('href', '')]
                            print(f"  DEBUG: Found {len(product_links)} potential product links on page")
                            
                            if product_links:
                                print(f"  DEBUG: Sample product links: {[link.get('href') for link in product_links[:3]]}")
                            
                        except Exception as debug_e:
                            print(f"  DEBUG: Error checking page content: {debug_e}")
                        
                except Exception as e:
                    print(f"Error accessing {target_url}: {e}")
                    continue
            
            unique_urls = list(set(camcorder_urls))
            print(f"\n📊 Camcorder Pagination Summary:")
            print(f"  Total unique camcorder products found: {len(unique_urls)}")
            print(f"  Returning all products for HTML saving")
            return unique_urls  # Return all unique URLs
            
        except Exception as e:
            print(f"Error in find_camcorders: {e}")
            return []

    def test_sony_access(self):
        """Test if we can access Sony's main site"""
        try:
            # Start browser
            self.start_browser()
            
            # Try the main Sony site first
            print("Testing access to main Sony site...")
            self.page.goto("https://electronics.sony.com", wait_until='domcontentloaded', timeout=30000)
            time.sleep(3)
            
            page_content = self.page.content()
            soup = BeautifulSoup(page_content, 'html.parser')
            
            print(f"Page title: {soup.title.string if soup.title else 'No title'}")
            print(f"Total links: {len(soup.find_all('a'))}")
            
            # Look for any shop links
            shop_links = soup.find_all('a', href=True)
            shop_urls = [link.get('href') for link in shop_links if 'shop' in link.get('href', '').lower() or '/c/' in link.get('href', '')]
            print(f"Shop links found: {shop_urls[:5]}")
            
            return len(shop_urls) > 0
            
        except Exception as e:
            print(f"Error testing Sony access: {e}")
            return False

    def save_urls_to_json(self, urls, company="sony", category="lens"):
        """Save discovered URLs to a JSON file for later use"""
        
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
    
    def load_urls_from_json(self, company="sony", category="body"):
        """Load URLs from JSON file"""
        
        filename = f"{company}_{category}_urls.json"
        filepath = Path("data/url_lists") / filename
        
        if not filepath.exists():
            print(f"❌ URL file not found: {filepath}")
            return None
        
        with open(filepath, 'r') as f:
            data = json.load(f)
        
        print(f"📄 Loaded {len(data['urls'])} URLs from: {filepath}")
        return data['urls']
    
    def scrape_in_batches(self, urls, company="sony", category="body", batch_size=120, start_index=0):
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
    scraper = SonyDataScraper()  # This calls __init__ automatically
    
    try:
        # Test access first
        print("=== Testing Sony Access ===")
        if scraper.test_sony_access():
            print("✅ Can access Sony website")
            
            # Configuration for bodies
            lens_company = "sony"
            lens_category = "lens"
            lens_batch_size = 100  # Process 120 URLs at a time
            lens_start_index = 0  # Start from 0
            
            print(f"\n=== Lens Scraping Configuration ===")
            print(f"Company: {lens_company}")
            print(f"Category: {lens_category}")
            print(f"Batch size: {lens_batch_size}")
            print(f"Start index: {lens_start_index}")
            
            # Process Bodies
            print(f"\n{'='*50}")
            print(f"=== PROCESSING LENSES ===")
            print(f"{'='*50}")
            
            # Try to load existing URLs first
            print(f"\n=== Loading Existing Lens URLs ===")
            lens_urls = scraper.load_urls_from_json(lens_company, lens_category)
            
            if lens_urls is None:
                # If no existing URLs, discover them and save to JSON
                print(f"\n=== Discovering Lens URLs ===")
                lens_urls = scraper.find_lens_pages()
                print(f"Found {len(lens_urls)} lens URLs")
                
                if lens_urls:
                    print(f"\n=== Saving Lens URLs to JSON ===")
                    scraper.save_urls_to_json(lens_urls, lens_company, lens_category)
            
            if lens_urls:
                print(f"\n=== Processing Lens URLs in Batches ===")
                print(f"Total URLs available: {len(lens_urls)}")
                
                # Process in batches
                saved_files, next_index = scraper.scrape_in_batches(
                    lens_urls, 
                    company=lens_company, 
                    category=lens_category, 
                    batch_size=lens_batch_size, 
                    start_index=lens_start_index
                )
                
                print(f"\n📊 Lens Batch Summary:")
                print(f"  ✅ Files saved: {len(saved_files)}")
                print(f"  📊 Next batch index: {next_index}")
                print(f"  📊 Remaining URLs: {len(lens_urls) - next_index}")
                
                if next_index < len(lens_urls):
                    print(f"\n💡 To continue lenses, update lens_start_index to {next_index}")
                else:
                    print(f"\n🎉 All lens URLs processed!")
            
            print(f"\n{'='*50}")
            print(f"=== SCRAPING COMPLETE ===")
            print(f"{'='*50}")
            
        else:
            print("❌ Cannot access Sony website")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        
    finally:
        scraper.stop_browser()