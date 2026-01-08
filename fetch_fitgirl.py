import requests
from bs4 import BeautifulSoup
import re
import json
import base64
import zlib
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Hash import SHA256
import base58

def search_fitgirl(search_query):
    """Search Fitgirl Repacks and extract article links"""
    
    # Replace spaces with '+' for URL
    formatted_query = search_query.replace(' ', '+')
    url = f"https://fitgirl-repacks.site/?s={formatted_query}"
    
    # Headers to mimic a browser request
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        print(f"Searching for: {search_query}")
        print(f"URL: {url}\n")
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        # Parse HTML and extract links
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Find all article tags
        articles = soup.find_all('article')
        
        # Extract links from article > h1 > a
        links = []
        for article in articles:
            h1 = article.find('h1')
            if h1:
                a_tag = h1.find('a')
                if a_tag and a_tag.get('href'):
                    title = a_tag.get_text(strip=True)
                    href = a_tag.get('href')
                    
                    # Skip "updates digest" links
                    if 'updates digest' not in title.lower():
                        links.append({'title': title, 'url': href})
        
        # Display extracted links
        print(f"🔗 Found {len(links)} results:\n")
        for idx, link in enumerate(links, 1):
            print(f"{idx}. {link['title']}")
        
        return links
            
    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        return None

def fetch_download_links(page_url):
    """Fetch download links from ul > li > a on the selected page"""
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        print(f"\n📥 Fetching download links from selected page...")
        response = requests.get(page_url, headers=headers, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Find links from div.entry-content > ul > li > a
        download_links = []
        entry_content = soup.find('div', class_='entry-content')
        
        if entry_content:
            for ul in entry_content.find_all('ul'):
                for li in ul.find_all('li'):
                    a_tag = li.find('a')
                    if a_tag and a_tag.get('href'):
                        text = a_tag.get_text(strip=True)
                        href = a_tag.get('href')
                        download_links.append({'text': text, 'url': href})
        
        print(f"\n🔗 Found {len(download_links)} links:\n")
        for idx, link in enumerate(download_links, 1):
            print(f"{idx}. {link['text']}")
            print(f"   {link['url']}\n")
        
        return download_links
        
    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        return None

def decrypt_privatebin_paste(paste_url):
    """
    Decrypt PrivateBin paste using pure Python (no browser required)
    
    CRITICAL IMPLEMENTATION NOTES:
    1. Authenticated data (adata) must use ORIGINAL base64 values, not decoded
    2. Key derivation must use SHA256 with PBKDF2
    3. Decompression must use raw deflate format (-zlib.MAX_WBITS)
    4. Base58 key may need padding to 32 bytes with null bytes at start
    """
    
    print(f"\n{'='*80}")
    print("🔓 DECRYPTING PRIVATEBIN PASTE (Pure Python - NO BROWSER)")
    print(f"{'='*80}\n")
    
    if '#' not in paste_url:
        print("✗ No encryption key in URL")
        return None
    
    base_url, key = paste_url.split('#', 1)
    paste_id = base_url.split('?')[-1] if '?' in base_url else None
    
    print(f"📋 Paste ID: {paste_id}")
    print(f"🔑 Key (base58): {key}")
    print(f"🔑 Key (truncated): {key[:20]}...\n")
    
    # Fetch encrypted data from API
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
    }
    
    try:
        api_url = f"{base_url.split('?')[0]}?pasteid={paste_id}"
        print(f"📥 Fetching from API: {api_url}")
        
        response = requests.get(api_url, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        print(f"✓ Got API response\n")
        
        if 'status' not in data or data['status'] != 0:
            print(f"✗ API error: {data}")
            return None
        
        # PrivateBin API returns the paste data differently
        # Check if data has 'ct' and 'adata' OR if it's in different format
        if 'ct' in data and 'adata' in data:
            ct = data['ct']
            adata = data['adata']
        elif 'data' in data:
            # Alternative format: data contains [ct, adata]
            ct = data['data'][0]
            adata = data['data'][1]
        else:
            print(f"✗ Unexpected data format: {data.keys()}")
            return None
        
        print("✓ Got encrypted data\n")
        
        print(f"📊 Data structure:")
        print(f"   Ciphertext: {len(ct)} chars")
        print(f"   Adata: {adata}\n")
        
        # Extract encryption spec (first element of adata)
        spec = adata[0]
        
        # spec[0] = IV (base64), spec[1] = salt (base64)
        iv_b64 = spec[0]
        salt_b64 = spec[1]
        iterations = spec[2]
        key_size = spec[3]
        tag_size = spec[4]
        
        print(f"🔧 Encryption parameters:")
        print(f"   Algorithm: AES-GCM")
        print(f"   Mode: {spec[5]}")
        print(f"   Compression: {spec[7]}")
        print(f"   Key size: {key_size} bits")
        print(f"   Tag size: {tag_size} bits")
        print(f"   Iterations: {iterations}")
        print(f"   IV (base64): {iv_b64}")
        print(f"   Salt (base64): {salt_b64}\n")
        
        # Decode key from base58
        key_bytes_raw = base58.b58decode(key)
        print(f"🔑 Decoded key: {len(key_bytes_raw)} bytes")
        
        # CRITICAL: PrivateBin pads the key to 32 bytes OR uses first 32 bytes
        # From JS: symmetricKey = CryptTool.base58decode(newKey).padStart(32, '\u0000');
        if len(key_bytes_raw) < 32:
            key_bytes = b'\x00' * (32 - len(key_bytes_raw)) + key_bytes_raw
            print(f"🔑 Key padded to: {len(key_bytes)} bytes")
        elif len(key_bytes_raw) > 32:
            key_bytes = key_bytes_raw[:32]
            print(f"🔑 Key truncated to: {len(key_bytes)} bytes")
        else:
            key_bytes = key_bytes_raw
        
        # Decode salt and IV
        salt = base64.b64decode(salt_b64)
        iv = base64.b64decode(iv_b64)
        print(f"🧂 Salt: {len(salt)} bytes")
        print(f"🔐 IV: {len(iv)} bytes")
        
        # Derive encryption key using PBKDF2 with SHA256
        derived_key = PBKDF2(key_bytes, salt, dkLen=key_size//8, count=iterations, hmac_hash_module=SHA256)
        print(f"🔑 Derived AES key: {len(derived_key)} bytes\n")
        
        # Decode ciphertext and extract auth tag
        ct_bytes = base64.b64decode(ct)
        tag_length = tag_size // 8
        ciphertext = ct_bytes[:-tag_length]
        tag = ct_bytes[-tag_length:]
        
        print(f"📦 Ciphertext: {len(ciphertext)} bytes")
        print(f"🏷️  Auth tag: {len(tag)} bytes\n")
        
        # CRITICAL DISCOVERY from PrivateBin source (js/privatebin.js lines 1304-1313):
        # JavaScript does:
        #   1. adataString = JSON.stringify(data[1])  <-- uses ORIGINAL base64 spec values
        #   2. spec[0] = atob(spec[0])                <-- THEN decodes for key/iv use
        #   3. spec[1] = atob(spec[1])
        # 
        # So authenticated data must use the BASE64 spec values, NOT decoded!
        
        # Use the ORIGINAL adata with base64 values for authentication
        adata_str = json.dumps(adata, separators=(',', ':'))
        
        print(f"📝 Authenticated data (with original base64 values):")
        print(f"   Length: {len(adata_str)} chars\n")
        
        # Decrypt - standard UTF-8 encoding for the adata string
        print("🔓 Decrypting...")
        cipher = AES.new(derived_key, AES.MODE_GCM, nonce=iv)
        
        # Use UTF-8 encoding (standard JSON string encoding)
        cipher.update(adata_str.encode('utf-8'))
        
        try:
            plaintext = cipher.decrypt_and_verify(ciphertext, tag)
            print("✅ Decryption successful!\n")
        except ValueError as e:
            print(f"✗ Decryption failed: {e}\n")
            return None
        
        # Decompress using raw deflate (no zlib header)
        print(f"📤 Decompressing ({spec[7]})...")
        try:
            # Use -zlib.MAX_WBITS for raw deflate format (no header)
            decompressed = zlib.decompress(plaintext, -zlib.MAX_WBITS)
            text = decompressed.decode('utf-8')
            print(f"✅ Decompressed: {len(text)} chars\n")
        except Exception as e:
            print(f"✗ Decompression failed: {e}")
            return None
        
        # Extract URLs
        urls = re.findall(r'https?://[^\s<>"\']+', text)
        print(f"✅ SUCCESS! Extracted {len(urls)} URLs\n")
        
        return urls
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return None

def process_download_links(download_links):
    """Process and display all available download providers"""
    
    # Find all paste bin links
    paste_links = [link for link in download_links if 'paste.fitgirl-repacks.site' in link['url']]
    
    if not paste_links:
        print("\n⚠️  No paste bin links found")
        return
    
    print(f"\n{'='*80}")
    print("📦 AVAILABLE DOWNLOAD PROVIDERS")
    print(f"{'='*80}\n")
    
    for idx, link in enumerate(paste_links, 1):
        print(f"{idx}. {link['text']}")
    
    # Let user select provider
    while True:
        try:
            choice = input("\nSelect provider number (or 'q' to quit): ").strip()
            
            if choice.lower() == 'q':
                return
            
            choice_num = int(choice)
            
            if 1 <= choice_num <= len(paste_links):
                selected_paste = paste_links[choice_num - 1]
                print(f"\n✓ Selected: {selected_paste['text']}\n")
                
                # Decrypt and extract links
                urls = decrypt_privatebin_paste(selected_paste['url'])
                
                if urls:
                    # Filter URLs based on provider
                    provider_name = selected_paste['text'].lower()
                    extracted_links = []
                    
                    # Extract provider keyword from text
                    if 'fuckingfast' in provider_name:
                        keyword = 'fuckingfast'
                    elif 'gofile' in provider_name:
                        keyword = 'gofile'
                    elif 'filecrypt' in provider_name:
                        keyword = 'filecrypt'
                    elif 'torrent' in provider_name:
                        keyword = 'torrent'
                    elif 'magnet' in provider_name:
                        keyword = 'magnet'
                    else:
                        # If no specific keyword, show all links
                        keyword = None
                    
                    if keyword:
                        extracted_links = [url for url in urls if keyword in url.lower()]
                    else:
                        extracted_links = urls
                    
                    if extracted_links:
                        print(f"\n{'='*80}")
                        print(f"📦 EXTRACTED {len(extracted_links)} LINKS")
                        print(f"{'='*80}\n")
                        for idx, url in enumerate(extracted_links, 1):
                            print(f"{idx}. {url}")
                        print()
                    else:
                        print(f"\n⚠️  No matching links found for {selected_paste['text']}")
                    
                    return extracted_links
                else:
                    print("⚠️  Decryption failed")
                    return None
                
            else:
                print(f"Enter a number between 1 and {len(paste_links)}")
                
        except ValueError:
            print("Invalid input!")

# Keep old function for backwards compatibility
def process_fuckingfast_links(download_links):
    """Filter and process fuckingfast links - LEGACY - Use process_download_links instead"""
    return process_download_links(download_links)

def main():
    # Get search query from user
    search_query = input("Enter search query: ").strip()
    
    if not search_query:
        print("No search query provided!")
        return
    
    # Search and get results
    links = search_fitgirl(search_query)
    
    if not links:
        print("No results found!")
        return
    
    # Let user select a link
    while True:
        try:
            choice = input("\nEnter the number to select a link (or 'q' to quit): ").strip()
            
            if choice.lower() == 'q':
                print("Exiting...")
                return
            
            choice_num = int(choice)
            
            if 1 <= choice_num <= len(links):
                selected = links[choice_num - 1]
                print(f"\n✓ Selected: {selected['title']}")
                print(f"   {selected['url']}")
                
                # Fetch download links from selected page
                download_links = fetch_download_links(selected['url'])
                
                if download_links:
                    # Process fuckingfast links
                    process_fuckingfast_links(download_links)
                
                break
            else:
                print(f"Please enter a number between 1 and {len(links)}")
                
        except ValueError:
            print("Invalid input! Please enter a number or 'q' to quit")

if __name__ == "__main__":
    main()
