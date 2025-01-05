// animeworld-scraper.js
function parseHTML(html) {
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
