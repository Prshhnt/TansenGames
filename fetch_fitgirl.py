import requests
from bs4 import BeautifulSoup
import re
import json
import base64
import zlib
from urllib.parse import urlsplit, urlunsplit
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Hash import SHA256
import base58
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import time

REQUEST_TIMEOUT = 12
CACHE_TTL_HOME = 180
CACHE_TTL_METADATA = 300

HOMEPAGE_URL = "https://fitgirl-repacks.site/"

_CACHE = {}


def _get_session() -> requests.Session:
    # Reuse a single session with retry to avoid reconnect overhead
    global _SESSION
    try:
        return _SESSION
    except NameError:
        _SESSION = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=0.5,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET"],
        )
        adapter = HTTPAdapter(pool_connections=10, pool_maxsize=10, max_retries=retry)
        _SESSION.mount("http://", adapter)
        _SESSION.mount("https://", adapter)
        return _SESSION


def _select_image_url(raw_url: str, image_size: str) -> str:
    if not raw_url:
        return None

    # thumb: return as-is (likely already a small resize from WP/Jetpack)
    if image_size == "thumb":
        return raw_url

    # medium: if filename has -WxH suffix, rewrite to a smaller target (e.g., 480px wide)
    if image_size == "medium":
        parsed = urlsplit(raw_url)
        path = parsed.path
        # Match patterns like name-768x432.jpg and replace dimensions
        new_path = re.sub(r"-(\d+)x(\d+)(\.[^.]+)$", r"-480x480\3", path)
        rebuilt = urlunsplit((parsed.scheme, parsed.netloc, new_path, parsed.query, parsed.fragment))
        return rebuilt

    # full: strip query to get original asset
    parsed = urlsplit(raw_url)
    return urlunsplit((parsed.scheme, parsed.netloc, parsed.path, '', ''))


def _cache_get(key: str):
    entry = _CACHE.get(key)
    now = time.time()
    if entry and entry["expires_at"] > now:
        print(f"🟢 Cache hit for {key}")
        return entry["value"]
    if entry:
        _CACHE.pop(key, None)
    return None


def _cache_set(key: str, value, ttl: int):
    _CACHE[key] = {"value": value, "expires_at": time.time() + ttl}


def _cache_invalidate(key: str):
    _CACHE.pop(key, None)

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
        response = _get_session().get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        # Parse HTML and extract links
        soup = BeautifulSoup(response.text, 'lxml')
        
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

def fetch_game_metadata(page_url, force_refresh: bool = False, image_size: str = "medium"):
    """
    Fetch comprehensive game metadata from a Fitgirl repack page
    
    Returns:
        dict with game metadata including poster, genres, companies, sizes, features, etc.
    """
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        cache_key = f"metadata:{page_url}:{image_size}"
        if not force_refresh:
            cached = _cache_get(cache_key)
            if cached is not None:
                return cached

        started = time.perf_counter()
        print(f"\n📥 Fetching game metadata from: {page_url}")
        response = _get_session().get(page_url, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'lxml')
        
        metadata = {
            'url': page_url,
            'title': '',
            'full_title': '',
            'update_number': '',
            'poster_url': '',
            'genres': [],
            'companies': '',
            'languages': '',
            'requirements': '',
            'original_size': '',
            'repack_size': '',
            'selective_download': False,
            'repack_features': [],
            'published_date': '',
            'modified_date': '',
            'description': ''
        }
        
        # Extract from JSON-LD schema (most reliable)
        script_tag = soup.find('script', {'type': 'application/ld+json', 'class': 'yoast-schema-graph'})
        if script_tag:
            try:
                schema_data = json.loads(script_tag.string)
                for item in schema_data.get('@graph', []):
                    if item.get('@type') == 'WebPage':
                        metadata['title'] = item.get('name', '').split(' - ')[0] if ' - ' in item.get('name', '') else item.get('name', '')
                        metadata['full_title'] = item.get('name', '')
                        metadata['poster_url'] = _select_image_url(item.get('thumbnailUrl', ''), image_size)
                        metadata['published_date'] = item.get('datePublished', '')
                        metadata['modified_date'] = item.get('dateModified', '')
            except Exception as e:
                print(f"⚠️  Failed to parse JSON-LD: {e}")
        
        # Extract from entry-content
        entry_content = soup.find('div', class_='entry-content')
        if entry_content:
            content_html = str(entry_content)

            def is_valid_genre(text: str) -> bool:
                clean = text.strip()
                if not clean:
                    return False
                # Skip obvious download/filehoster strings that sometimes get swept in
                bad_patterns = r"(filehoster|\.rar|\.bin|paste\.fitgirl|fitgirl-repacks|part\d|optional-|\.exe)"
                return not re.search(bad_patterns, clean, re.IGNORECASE)

            def clean_lines_from_li(li_tag):
                # Replace <br> with newlines and split, keep non-empty lines
                for br in li_tag.find_all('br'):
                    br.replace_with('\n')
                parts = [p.strip() for p in li_tag.get_text().split('\n') if p.strip()]
                return parts if parts else [li_tag.get_text(strip=True)]

            def is_valid_feature(text: str) -> bool:
                clean = text.strip()
                if not clean:
                    return False
                # Drop obvious download/mirror/file entries and raw links
                bad_patterns = r"(filehoster|\.rar|\.bin|part\d|paste\.fitgirl|multiupload|onedrive|magnet:|http[s]?://|click to show direct links)"
                return not re.search(bad_patterns, clean, re.IGNORECASE)

            def collect_features_from_ul(ul_tag):
                if not ul_tag:
                    return
                for li in ul_tag.find_all('li'):
                    for line in clean_lines_from_li(li):
                        if line and is_valid_feature(line) and line not in metadata['repack_features']:
                            metadata['repack_features'].append(line)

            def find_features_ul(root):
                # Prefer UL directly following a heading containing "Repack Features" in the given root
                for heading in root.find_all(['h2', 'h3', 'h4', 'p', 'div']):
                    heading_text = heading.get_text(' ', strip=True).lower()
                    if 'repack feature' in heading_text:
                        sibling = heading.find_next_sibling()
                        while sibling and sibling.name not in ['h1', 'h2', 'h3', 'h4']:
                            if sibling.name == 'ul':
                                return sibling
                            sibling = sibling.find_next_sibling()
                        fallback_ul = heading.find_next('ul')
                        if fallback_ul:
                            return fallback_ul
                return None

            search_roots = [entry_content]
            article_root = soup.find('article')
            if article_root and article_root not in search_roots:
                search_roots.append(article_root)
            search_roots.append(soup)

            features_list = None
            for root in search_roots:
                if not root:
                    continue
                features_list = find_features_ul(root)
                if features_list:
                    break

            if features_list:
                collect_features_from_ul(features_list)

            # Heuristic fallback: locate a descriptive UL even without an explicit heading
            if not metadata['repack_features']:
                for root in search_roots:
                    if not root:
                        continue
                    for ul in root.find_all('ul'):
                        li_texts = [li.get_text(' ', strip=True) for li in ul.find_all('li', recursive=False) if li.get_text(strip=True)]
                        if not li_texts:
                            continue
                        avg_len = sum(len(t) for t in li_texts) / len(li_texts)
                        if len(li_texts) < 5 or avg_len < 30:
                            continue
                        if any(re.search(r'(filehoster|magnet|torrent|filecrypt|multiupload|gofile|rar)', t, re.IGNORECASE) for t in li_texts):
                            continue
                        collect_features_from_ul(ul)
                        if metadata['repack_features']:
                            break
                    if metadata['repack_features']:
                        break
                        genre = a_tag.get_text(strip=True)
                        if genre and genre not in metadata['genres']:
                            metadata['genres'].append(genre)

            # Filter out download artefacts accidentally captured as genres
            metadata['genres'] = [g for g in metadata['genres'] if is_valid_genre(g)]
            
            # Extract companies
            companies_match = re.search(r'Companies:\s*<strong>(.*?)</strong>', content_html)
            if companies_match:
                metadata['companies'] = companies_match.group(1)
            
            # Extract languages
            languages_match = re.search(r'Languages:\s*<strong>(.*?)</strong>', content_html)
            if languages_match:
                metadata['languages'] = languages_match.group(1)
            
            # Extract original size
            size_match = re.search(r'Original Size:\s*<strong>(.*?)</strong>', content_html)
            if size_match:
                metadata['original_size'] = size_match.group(1)
            
            # Extract repack size
            repack_match = re.search(r'Repack Size:\s*<strong>(.*?)</strong>', content_html)
            if repack_match:
                repack_size = repack_match.group(1)
                metadata['repack_size'] = repack_size
                metadata['selective_download'] = 'Selective' in repack_size or 'selective' in repack_size.lower()
            
            # Extract requirements
            req_match = re.search(r'Requires Windows ([^<]+)', content_html)
            if req_match:
                metadata['requirements'] = f"Windows {req_match.group(1)}"
            
            def collect_features_from_ul(ul_tag):
                if not ul_tag:
                    return
                for li in ul_tag.find_all('li'):
                    for line in clean_lines_from_li(li):
                        if line and is_valid_feature(line) and line not in metadata['repack_features']:
                            metadata['repack_features'].append(line)

            def find_features_ul():
                # Prefer UL directly following a heading containing "Repack Features"
                for heading in entry_content.find_all(['h1', 'h2', 'h3', 'h4', 'p', 'div']):
                    heading_text = heading.get_text(' ', strip=True).lower()
                    if 'repack feature' in heading_text:
                        # Walk siblings until next heading to avoid jumping into download lists
                        sibling = heading.find_next_sibling()
                        while sibling and sibling.name not in ['h1', 'h2', 'h3', 'h4']:
                            if sibling.name == 'ul':
                                return sibling
                            sibling = sibling.find_next_sibling()
                        fallback_ul = heading.find_next('ul')
                        if fallback_ul:
                            return fallback_ul
                return None

            features_list = find_features_ul()
            if features_list:
                collect_features_from_ul(features_list)

            # Heuristic fallback: locate a descriptive UL even without an explicit heading
            if not metadata['repack_features']:
                for ul in entry_content.find_all('ul'):
                    li_texts = [li.get_text(' ', strip=True) for li in ul.find_all('li', recursive=False) if li.get_text(strip=True)]
                    if not li_texts:
                        continue
                    avg_len = sum(len(t) for t in li_texts) / len(li_texts)
                    # Skip obvious download/mirror lists
                    if len(li_texts) < 4 or avg_len < 25:
                        continue
                    if any(re.search(r'(filehoster|magnet|torrent|filecrypt|multiupload|gofile|paste\.fitgirl)', t, re.IGNORECASE) for t in li_texts):
                        continue
                    collect_features_from_ul(ul)
                    if metadata['repack_features']:
                        break

            # Final cleanup: drop any lingering download/mirror artefacts
            metadata['repack_features'] = [f for f in metadata['repack_features'] if is_valid_feature(f)]
            
            # Extract description from first paragraph (if available)
            first_p = entry_content.find('p')
            if first_p and 'Genres/Tags:' not in first_p.get_text():
                desc_text = first_p.get_text(strip=True)
                if len(desc_text) > 50:  # Only use if substantial
                    metadata['description'] = desc_text[:500]  # Limit to 500 chars
        
        print(f"✓ Extracted metadata for: {metadata['title']}")
        _cache_set(cache_key, metadata, CACHE_TTL_METADATA)
        print(f"⏱️ metadata scrape {time.perf_counter() - started:.2f}s (cache miss)")
        return metadata
        
    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        _cache_invalidate(cache_key)
        return None

def fetch_popular_repacks(force_refresh: bool = False, image_size: str = "medium"):
    """Fetch popular repacks from the popular repacks page with TTL caching."""
    cache_key = f"popular:{image_size}"
    if not force_refresh:
        cached = _cache_get(cache_key)
        if cached is not None:
            return cached

    started = time.perf_counter()

    url = "https://fitgirl-repacks.site/popular-repacks/"

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }

    try:
        print(f"📥 Fetching popular repacks...")
        print(f"URL: {url}\n")
        response = _get_session().get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()

        soup = BeautifulSoup(response.text, 'lxml')

        links = []

        # Primary source (visible grid widget on sidebar)
        widget = soup.find('div', class_='jetpack_top_posts_widget')
        if widget:
            for anchor in widget.select('div.widget-grid-view-image a'):
                href = anchor.get('href')
                title = anchor.get('title') or anchor.get_text(strip=True)
                poster_url = None
                img_tag = anchor.find('img')
                if img_tag:
                    raw_poster = img_tag.get('src') or img_tag.get('data-src')
                    if raw_poster:
                        poster_url = _select_image_url(raw_poster, image_size)
                if href and title and 'updates digest' not in title.lower():
                    links.append({'title': title, 'url': href, 'poster_url': poster_url})

        # Fallback: old structure article > h1 > a
        if not links:
            articles = soup.find_all('article')
            for article in articles:
                h1 = article.find('h1')
                if h1:
                    a_tag = h1.find('a')
                    if a_tag and a_tag.get('href'):
                        title = a_tag.get_text(strip=True)
                        href = a_tag.get('href')
                        if 'updates digest' not in title.lower():
                            links.append({'title': title, 'url': href, 'poster_url': None})

        print(f"🔗 Found {len(links)} popular repacks:\n")
        for idx, link in enumerate(links, 1):
            print(f"{idx}. {link['title']}")

        _cache_set(cache_key, links, CACHE_TTL_HOME)
        print(f"⏱️ popular scrape {time.perf_counter() - started:.2f}s (cache miss)")
        return links

    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        _cache_invalidate(cache_key)
        return None


def _parse_latest_widget(soup: BeautifulSoup, max_items: int = 12, image_size: str = "medium"):
    items = []
    widget = soup.find(id="wplp_widget_13066")
    if not widget:
        return items

    def split_title_version(alt_text: str):
        if not alt_text:
            return "", ""
        parts = [p.strip() for p in alt_text.split(" – ") if p.strip()]
        if len(parts) >= 2:
            return parts[0], " – ".join(parts[1:])
        return parts[0], ""

    for slide in widget.select('.wplp_listposts .swiper-slide'):
        anchor = slide.find('a', class_='thumbnail')
        img = anchor.find('img') if anchor else None
        href = anchor.get('href') if anchor else None
        img_src = img.get('src') if img else None
        alt_text = img.get('alt', '') if img else ''
        title, version = split_title_version(alt_text)
        if href and title:
            items.append({
                'title': title,
                'url': href,
                'image': _select_image_url(img_src, image_size),
                'version': version,
                'published_date': '',  # homepage widget doesn’t expose date
                'repack_size': ''
            })
        if len(items) >= max_items:
            break
    return items


def _parse_upcoming_list(soup: BeautifulSoup):
    upcoming = []
    # Find the "Upcoming Repacks" post on the homepage
    for article in soup.find_all('article'):
        h1 = article.find('h1')
        if h1 and 'upcoming repacks' in h1.get_text(strip=True).lower():
            content = article.find('div', class_='entry-content') or article
            # Look for green spans or lines with the ⇢ marker
            for span in content.find_all('span'):
                style = span.get('style', '')
                if '#339966' in style or 'color: #339966' in style:
                    text = span.get_text(strip=True)
                    if text:
                        upcoming.append(text)
            # Fallback: lines starting with the arrow
            if not upcoming:
                for t in content.stripped_strings:
                    if t.startswith('⇢'):
                        upcoming.append(t)
            break
    return upcoming


def fetch_home_latest(max_items: int = 12, force_refresh: bool = False):
    """Fetch latest repacks list from the homepage widget with a short TTL cache."""
    def fetch_home_latest(max_items: int = 12, force_refresh: bool = False, image_size: str = "medium"):
        """Fetch latest repacks list from the homepage widget with a short TTL cache."""
        cache_key = f"home_latest:{max_items}:{image_size}"
    if not force_refresh:
        cached = _cache_get(cache_key)
        if cached is not None:
            return cached

    started = time.perf_counter()
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = _get_session().get(HOMEPAGE_URL, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'lxml')
        latest = _parse_latest_widget(soup, max_items=max_items, image_size=image_size)
        if latest is not None:
            _cache_set(cache_key, latest, CACHE_TTL_HOME)
        print(f"⏱️ latest scrape {time.perf_counter() - started:.2f}s (cache miss)")
        return latest
    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        _cache_invalidate(cache_key)
        return None


def fetch_upcoming_list():
    """Fetch upcoming repacks list from the homepage."""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = _get_session().get(HOMEPAGE_URL, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'lxml')
        return _parse_upcoming_list(soup)
    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        return None


def fetch_home(max_items: int = 12, force_refresh: bool = False, image_size: str = "medium"):
    """Aggregate homepage data: featured, latest, upcoming, popular with TTL caching."""
    cache_key = f"home:{max_items}:{image_size}"
    if not force_refresh:
        cached = _cache_get(cache_key)
        if cached is not None:
            return cached

    started = time.perf_counter()
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = _get_session().get(HOMEPAGE_URL, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'lxml')
        latest = _parse_latest_widget(soup, max_items=max_items, image_size=image_size)
        featured = latest[0] if latest else None
        upcoming = _parse_upcoming_list(soup)
        popular = fetch_popular_repacks(force_refresh=force_refresh, image_size=image_size) or []
        payload = {
            'featured': featured,
            'latest': latest,
            'upcoming': upcoming,
            'popular': popular
        }
        _cache_set(cache_key, payload, CACHE_TTL_HOME)
        print(f"⏱️ home scrape {time.perf_counter() - started:.2f}s (cache miss)")
        return payload
    except requests.exceptions.RequestException as e:
        print(f"✗ Error occurred: {e}")
        _cache_invalidate(cache_key)
        return None

def fetch_download_links(page_url):
    """Fetch download links from ul > li > a on the selected page"""
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        print(f"\n📥 Fetching download links from selected page...")
        response = _get_session().get(page_url, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'lxml')
        
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
        
        response = _get_session().get(api_url, headers=headers, timeout=REQUEST_TIMEOUT)
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

def fetch_fuckingfast_page(fuckingfast_url, save_html=True):
    """
    Fetch FuckingFast page and extract actual download button links
    
    FuckingFast pages typically have download buttons/links that need to be extracted
    from the HTML after visiting the initial URL
    """
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Referer': 'https://fitgirl-repacks.site/',
    }
    
    try:
        print(f"\n🌐 Fetching FuckingFast page...")
        print(f"   URL: {fuckingfast_url}")
        
        response = _get_session().get(fuckingfast_url, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        # Save HTML for analysis
        if save_html:
            filename = f"fuckingfast_page_{fuckingfast_url.split('/')[-1].split('#')[0]}.html"
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(response.text)
            print(f"   💾 Saved HTML to: {filename}")
        
        soup = BeautifulSoup(response.text, 'lxml')
        
        # Debug: Print page title and basic info
        title = soup.find('title')
        print(f"   📄 Page title: {title.get_text(strip=True) if title else 'No title'}")
        
        # Count all links
        all_links = soup.find_all('a', href=True)
        print(f"   🔗 Total links on page: {len(all_links)}")
        
        # Look for download links/buttons - common patterns:
        # 1. Links with "download" in text or class
        # 2. Buttons with download functionality
        # 3. Direct file links
        
        download_buttons = []
        
        # Extract download URL from JavaScript - FuckingFast specific
        # Look for window.open("URL") pattern in script tags
        scripts = soup.find_all('script')
        for script in scripts:
            if script.string:
                # Search for window.open("https://fuckingfast.co/dl/...") pattern
                download_match = re.search(r'window\.open\(["\']([^"\']+)["\']', script.string)
                if download_match:
                    download_url = download_match.group(1)
                    download_buttons.append({
                        'text': 'Direct Download Link',
                        'url': download_url
                    })
                    print(f"   ✓ Found download URL in JavaScript: {download_url[:100]}")
        
        # Print first 10 links for debugging (if no download found)
        if not download_buttons:
            print(f"\n   📋 First 10 links found:")
            for idx, a_tag in enumerate(all_links[:10], 1):
                href = a_tag.get('href')
                text = a_tag.get_text(strip=True)
                classes = a_tag.get('class', [])
                print(f"      {idx}. Text: '{text[:50]}' | Class: {classes} | Href: {href[:80]}")
        
        print(f"\n   ✓ Found {len(download_buttons)} download links on page\n")
        
        return download_buttons
        
    except requests.exceptions.RequestException as e:
        print(f"✗ Error fetching FuckingFast page: {e}")
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
                        
                        # If this is FuckingFast, fetch the actual download pages (first 2 parts only)
                        if 'fuckingfast' in provider_name:
                            print(f"\n{'='*80}")
                            print("🚀 ANALYZING FUCKINGFAST PAGES FOR DOWNLOAD BUTTONS (First 2 Parts)")
                            print(f"{'='*80}\n")
                            
                            all_download_buttons = []
                            links_to_check = extracted_links[:2]  # Only check first 2 parts
                            
                            for idx, ff_url in enumerate(links_to_check, 1):
                                print(f"\n[Part {idx}/2] Processing: {ff_url}")
                                buttons = fetch_fuckingfast_page(ff_url)
                                
                                if buttons:
                                    print(f"   Found {len(buttons)} download options:")
                                    for btn in buttons:
                                        print(f"      • {btn['text']}: {btn['url']}")
                                        all_download_buttons.append(btn)
                                else:
                                    print(f"   ⚠️  No download buttons found")
                            
                            if all_download_buttons:
                                print(f"\n{'='*80}")
                                print(f"✅ TOTAL: {len(all_download_buttons)} DOWNLOAD BUTTONS FOUND")
                                print(f"{'='*80}\n")
                                return {
                                    'original_links': extracted_links,
                                    'download_buttons': all_download_buttons
                                }
                        
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
