import requests
from bs4 import BeautifulSoup

def scrape_titles(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    titles = [title.get_text() for title in soup.find_all('h1')]
    return titles


# Usage
titles = scrape_titles('https://example.com')
print(titles)