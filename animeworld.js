// animeworld-scraper.js
async function search(query) {
    // Fetch the search results
    const html = fetch(
        `https://www.animeworld.so/search?keyword=${encodeURIComponent(query)}`,
        JSON.stringify({
            headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
            }
        })
    );
    
    // Parse the results
    const results = [];
    
    // Find all item divs
    const itemRegex = /<div class="item">[\s\S]*?<\/div>[\s]*<\/div>/g;
    const items = html.match(itemRegex) || [];
    
    items.forEach(itemHtml => {
        // Extract image URL
        const imgMatch = itemHtml.match(/src="([^"]+)"/);
        const imageUrl = imgMatch ? imgMatch[1] : '';
        
        // Extract title
        const titleMatch = itemHtml.match(/class="name">([^<]+)</);
        const title = titleMatch ? titleMatch[1] : '';
        
        if (imageUrl && title) {
            results.push({
                title: title.trim(),
                image: imageUrl
            });
        }
    });
    
    return results;
}
