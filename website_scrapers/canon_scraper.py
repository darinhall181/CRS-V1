import requests
from bs4 import BeautifulSoup
import pandas as pd
import json
import time
from urllib.parse import urljoin, urlparse
import pdfplumber
import re
from pathlib import Path
import xml.etree.ElementTree as ET

'''
All the below code was created using Claude. Used as a test scraper to see what information may be able to be extracted from Canon's website. 
'''

class CanonDataScraper:
    def __init__(self):
        self.base_url = "https://www.canon.com"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
        
    def get_sitemap_urls(self, sitemap_url):
        """Extract URLs from XML sitemap"""
        try:
            response = self.session.get(sitemap_url)
            response.raise_for_status()
            
            root = ET.fromstring(response.content)
            urls = []
            
            # Handle different sitemap namespaces
            for url_elem in root.findall('.//{http://www.sitemaps.org/schemas/sitemap/0.9}url'):
                loc = url_elem.find('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')
                if loc is not None:
                    urls.append(loc.text)
            
            return urls
        except Exception as e:
            print(f"Error parsing sitemap: {e}")
            return []
    
    def find_camera_pages(self, search_terms=['camera', 'lens', 'dslr', 'mirrorless']):
        """Find camera-related pages from sitemap or by crawling"""
        camera_urls = []
        
        # Try to get sitemap first
        sitemap_urls = [
            f"{self.base_url}/sitemap.xml",
            f"{self.base_url}/robots.txt"
        ]
        
        for sitemap_url in sitemap_urls:
            try:
                response = self.session.get(sitemap_url)
                if response.status_code == 200:
                    if 'sitemap' in response.text.lower():
                        urls = self.get_sitemap_urls(sitemap_url)
                        camera_urls.extend([url for url in urls if any(term in url.lower() for term in search_terms)])
                        break
            except:
                continue
        
        # If no sitemap, try manual discovery
        if not camera_urls:
            try:
                # Try common camera section URLs
                camera_sections = [
                    f"{self.base_url}/cameras",
                    f"{self.base_url}/products/cameras",
                    f"{self.base_url}/en/cameras"
                ]
                
                for section_url in camera_sections:
                    try:
                        response = self.session.get(section_url)
                        if response.status_code == 200:
                            soup = BeautifulSoup(response.content, 'html.parser')
                            links = soup.find_all('a', href=True)
                            for link in links:
                                href = urljoin(section_url, link['href'])
                                if any(term in href.lower() for term in search_terms):
                                    camera_urls.append(href)
                            break
                    except:
                        continue
            except Exception as e:
                print(f"Error in manual discovery: {e}")
        
        return list(set(camera_urls))[:10]  # Limit to 10 for testing
    
    def scrape_website_specs(self, url):
        """Scrape camera specifications from Canon website"""
        try:
            response = self.session.get(url)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
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
            
            # Try to find title
            title_selectors = ['h1', '.product-title', '.page-title', 'title']
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
    
    def extract_pdf_specs(self, pdf_path):
        """Extract specifications from Canon PDF"""
        try:
            product_data = {
                'source': pdf_path,
                'title': '',
                'specifications': {},
                'text_content': ''
            }
            
            with pdfplumber.open(pdf_path) as pdf:
                full_text = ""
                
                for page in pdf.pages:
                    # Extract text
                    page_text = page.extract_text()
                    if page_text:
                        full_text += page_text + "\n"
                    
                    # Extract tables
                    tables = page.extract_tables()
                    for table in tables:
                        for row in table:
                            if row and len(row) >= 2:
                                key = str(row[0]).strip() if row[0] else ""
                                value = str(row[1]).strip() if row[1] else ""
                                if key and value and key.lower() != 'specification':
                                    product_data['specifications'][key] = value
                
                product_data['text_content'] = full_text
                
                # Try to extract title from first page
                lines = full_text.split('\n')[:10]
                for line in lines:
                    if any(word in line.lower() for word in ['camera', 'lens', 'canon']):
                        if len(line.strip()) > 5 and len(line.strip()) < 100:
                            product_data['title'] = line.strip()
                            break
                
                # Extract structured specs from text using regex
                spec_patterns = [
                    r'([A-Za-z\s]+?):\s*([^\n]+)',
                    r'([A-Za-z\s]+?)\s*-\s*([^\n]+)',
                    r'([A-Za-z\s]+?)\s*:\s*([^\n]+)'
                ]
                
                for pattern in spec_patterns:
                    matches = re.findall(pattern, full_text)
                    for match in matches:
                        key, value = match
                        key = key.strip()
                        value = value.strip()
                        if len(key) > 2 and len(value) > 1 and len(key) < 50:
                            product_data['specifications'][key] = value
            
            return product_data
            
        except Exception as e:
            print(f"Error extracting PDF {pdf_path}: {e}")
            return None
    
    def download_pdf(self, pdf_url, filename):
        """Download PDF from URL"""
        try:
            response = self.session.get(pdf_url)
            response.raise_for_status()
            
            with open(filename, 'wb') as f:
                f.write(response.content)
            
            return filename
            
        except Exception as e:
            print(f"Error downloading PDF: {e}")
            return None
    
    def compare_methods(self, sample_size=3):
        """Compare website scraping vs PDF extraction"""
        print("🔍 Starting Canon data extraction comparison...")
        
        # Find camera pages
        print("📋 Finding camera pages...")
        camera_urls = self.find_camera_pages()
        
        if not camera_urls:
            print("❌ No camera URLs found. Let's try some manual URLs...")
            # Fallback to known Canon camera pages
            camera_urls = [
                "https://www.canon.com/cameras/eos-r5",
                "https://www.canon.com/cameras/eos-r6",
                "https://www.canon.com/cameras/eos-90d"
            ]
        
        print(f"📊 Found {len(camera_urls)} camera URLs")
        
        # Test website scraping
        print("\n🌐 Testing website scraping...")
        website_results = []
        
        for i, url in enumerate(camera_urls[:sample_size]):
            print(f"  Processing {i+1}/{sample_size}: {url}")
            result = self.scrape_website_specs(url)
            if result:
                website_results.append(result)
            time.sleep(1)  # Be respectful
        
        # For PDF testing, we'll use sample Canon PDFs
        print("\n📄 Testing PDF extraction...")
        pdf_results = []
        
        # Sample Canon press release PDFs (these are examples - you'd need actual URLs)
        sample_pdfs = [
            "https://www.canon.com/news/press-releases/2020/eos-r5-specifications.pdf",
            "https://www.canon.com/news/press-releases/2021/eos-r6-specifications.pdf"
        ]
        
        for i, pdf_url in enumerate(sample_pdfs[:sample_size]):
            print(f"  Processing PDF {i+1}: {pdf_url}")
            filename = f"canon_specs_{i+1}.pdf"
            
            # Download and extract
            if self.download_pdf(pdf_url, filename):
                result = self.extract_pdf_specs(filename)
                if result:
                    pdf_results.append(result)
            
            time.sleep(1)
        
        # Compare results
        print("\n📊 COMPARISON RESULTS:")
        print("=" * 50)
        
        print(f"\nWebsite Scraping Results ({len(website_results)} successful):")
        for i, result in enumerate(website_results, 1):
            print(f"  {i}. {result['title']}")
            print(f"     Specifications found: {len(result['specifications'])}")
            print(f"     Images found: {len(result['images'])}")
            print(f"     Sample specs: {list(result['specifications'].keys())[:3]}")
        
        print(f"\nPDF Extraction Results ({len(pdf_results)} successful):")
        for i, result in enumerate(pdf_results, 1):
            print(f"  {i}. {result['title']}")
            print(f"     Specifications found: {len(result['specifications'])}")
            print(f"     Sample specs: {list(result['specifications'].keys())[:3]}")
        
        return {
            'website_results': website_results,
            'pdf_results': pdf_results,
            'summary': {
                'website_success_rate': len(website_results) / sample_size,
                'pdf_success_rate': len(pdf_results) / sample_size,
                'avg_website_specs': sum(len(r['specifications']) for r in website_results) / max(len(website_results), 1),
                'avg_pdf_specs': sum(len(r['specifications']) for r in pdf_results) / max(len(pdf_results), 1)
            }
        }

# Usage example
if __name__ == "__main__":
    scraper = CanonDataScraper()
    
    # Run comparison
    results = scraper.compare_methods(sample_size=3)
    
    # Save results
    with open('canon_scraping_comparison.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    print("\n✅ Comparison complete! Results saved to 'canon_scraping_comparison.json'")
    print("\nNext steps:")
    print("1. Review the quality of extracted data")
    print("2. Identify which method gives more complete specifications")
    print("3. Consider hybrid approach using both methods")
    print("4. Test with other manufacturers (Sony, Nikon, etc.)")