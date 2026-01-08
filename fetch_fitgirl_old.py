import requests
from bs4 import BeautifulSoup

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
                fetch_download_links(selected['url'])
                break
            else:
                print(f"Please enter a number between 1 and {len(links)}")
                
        except ValueError:
            print("Invalid input! Please enter a number or 'q' to quit")

if __name__ == "__main__":
    main()
