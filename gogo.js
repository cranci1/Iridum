// gogoanime-scraper.js
async function search(query) {
    const html = fetch(
        `https://anitaku.bz/search.html?keyword=${encodeURIComponent(query)}`,
        JSON.stringify({
            headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            }
        })
    );
    
    const results = [];
    
    // Different parsing logic for GoGoAnime's HTML structure
    const itemRegex = /<div class="img">[\s\S]*?<\/p>/g;
    const items = html.match(itemRegex) || [];
    
    items.forEach(itemHtml => {
        const imgMatch = itemHtml.match(/src="([^"]+)"/);
        const titleMatch = itemHtml.match(/title="([^"]+)"/);
        
        if (imgMatch && titleMatch) {
            results.push({
                title: titleMatch[1].trim(),
                image: imgMatch[1]
            });
        }
    });
    
    return results;
}
