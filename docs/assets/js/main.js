// ============================================================================
// CLOUDWALKER INFRASTRUCTURE DOCUMENTATION JAVASCRIPT
// ============================================================================
// Enhanced functionality for the documentation website
// ============================================================================

document.addEventListener('DOMContentLoaded', function() {
    
    // ========================================================================
    // TABLE OF CONTENTS GENERATION
    // ========================================================================
    function generateTableOfContents() {
        const headings = document.querySelectorAll('h2, h3, h4');
        if (headings.length === 0) return;
        
        const tocContainer = document.createElement('div');
        tocContainer.className = 'table-of-contents';
        tocContainer.innerHTML = '<h3>📋 Table of Contents</h3>';
        
        const tocList = document.createElement('ul');
        
        headings.forEach((heading, index) => {
            // Create anchor ID if it doesn't exist
            if (!heading.id) {
                heading.id = heading.textContent.toLowerCase()
                    .replace(/[^\w\s-]/g, '')
                    .replace(/\s+/g, '-');
            }
            
            const listItem = document.createElement('li');
            const link = document.createElement('a');
            link.href = `#${heading.id}`;
            link.textContent = heading.textContent;
            link.className = `toc-${heading.tagName.toLowerCase()}`;
            
            listItem.appendChild(link);
            tocList.appendChild(listItem);
        });
        
        tocContainer.appendChild(tocList);
        
        // Insert TOC after the first paragraph or at the beginning
        const firstParagraph = document.querySelector('.page-content p');
        if (firstParagraph) {
            firstParagraph.parentNode.insertBefore(tocContainer, firstParagraph.nextSibling);
        } else {
            const pageContent = document.querySelector('.page-content');
            if (pageContent) {
                pageContent.insertBefore(tocContainer, pageContent.firstChild);
            }
        }
    }
    
    // ========================================================================
    // CODE BLOCK ENHANCEMENTS
    // ========================================================================
    function enhanceCodeBlocks() {
        const codeBlocks = document.querySelectorAll('pre code');
        
        codeBlocks.forEach(block => {
            const pre = block.parentElement;
            
            // Add copy button
            const copyButton = document.createElement('button');
            copyButton.className = 'copy-button';
            copyButton.innerHTML = '📋 Copy';
            copyButton.title = 'Copy to clipboard';
            
            copyButton.addEventListener('click', async () => {
                try {
                    await navigator.clipboard.writeText(block.textContent);
                    copyButton.innerHTML = '✅ Copied!';
                    copyButton.style.background = '#28a745';
                    
                    setTimeout(() => {
                        copyButton.innerHTML = '📋 Copy';
                        copyButton.style.background = '';
                    }, 2000);
                } catch (err) {
                    console.error('Failed to copy text: ', err);
                    copyButton.innerHTML = '❌ Failed';
                    setTimeout(() => {
                        copyButton.innerHTML = '📋 Copy';
                    }, 2000);
                }
            });
            
            // Create wrapper for positioning
            const wrapper = document.createElement('div');
            wrapper.className = 'code-block-wrapper';
            pre.parentNode.insertBefore(wrapper, pre);
            wrapper.appendChild(pre);
            wrapper.appendChild(copyButton);
        });
    }
    
    // ========================================================================
    // SEARCH FUNCTIONALITY
    // ========================================================================
    function addSearchFunctionality() {
        const searchContainer = document.createElement('div');
        searchContainer.className = 'search-container';
        searchContainer.innerHTML = `
            <div class="search-box">
                <input type="text" id="search-input" placeholder="🔍 Search documentation..." />
                <div id="search-results" class="search-results"></div>
            </div>
        `;
        
        const header = document.querySelector('.site-header .wrapper');
        if (header) {
            header.appendChild(searchContainer);
        }
        
        const searchInput = document.getElementById('search-input');
        const searchResults = document.getElementById('search-results');
        
        // Simple search implementation
        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();
            
            if (query.length < 2) {
                searchResults.style.display = 'none';
                return;
            }
            
            const content = document.querySelector('.page-content');
            const elements = content.querySelectorAll('h1, h2, h3, h4, p, td');
            const results = [];
            
            elements.forEach(element => {
                if (element.textContent.toLowerCase().includes(query)) {
                    const heading = element.closest('section') || 
                                  element.previousElementSibling?.tagName?.match(/H[1-6]/) ? 
                                  element.previousElementSibling : element;
                    
                    results.push({
                        text: element.textContent.substring(0, 100) + '...',
                        element: element,
                        heading: heading.textContent || 'Content'
                    });
                }
            });
            
            displaySearchResults(results.slice(0, 5), query);
        });
        
        function displaySearchResults(results, query) {
            if (results.length === 0) {
                searchResults.innerHTML = '<div class="no-results">No results found</div>';
            } else {
                searchResults.innerHTML = results.map(result => `
                    <div class="search-result" onclick="scrollToElement(this)" data-element="${result.element.id || ''}">
                        <div class="result-heading">${result.heading}</div>
                        <div class="result-text">${highlightText(result.text, query)}</div>
                    </div>
                `).join('');
            }
            searchResults.style.display = 'block';
        }
        
        function highlightText(text, query) {
            const regex = new RegExp(`(${query})`, 'gi');
            return text.replace(regex, '<mark>$1</mark>');
        }
        
        // Close search results when clicking outside
        document.addEventListener('click', function(e) {
            if (!searchContainer.contains(e.target)) {
                searchResults.style.display = 'none';
            }
        });
    }
    
    // ========================================================================
    // SCROLL TO ELEMENT FUNCTION
    // ========================================================================
    window.scrollToElement = function(element) {
        const targetId = element.getAttribute('data-element');
        const targetElement = document.getElementById(targetId);
        
        if (targetElement) {
            targetElement.scrollIntoView({ behavior: 'smooth' });
            targetElement.style.backgroundColor = '#fff3cd';
            setTimeout(() => {
                targetElement.style.backgroundColor = '';
            }, 2000);
        }
        
        document.getElementById('search-results').style.display = 'none';
    };
    
    // ========================================================================
    // SMOOTH SCROLLING FOR ANCHOR LINKS
    // ========================================================================
    function enableSmoothScrolling() {
        const links = document.querySelectorAll('a[href^="#"]');
        
        links.forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                
                const targetId = this.getAttribute('href').substring(1);
                const targetElement = document.getElementById(targetId);
                
                if (targetElement) {
                    targetElement.scrollIntoView({ 
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });
    }
    
    // ========================================================================
    // BACK TO TOP BUTTON
    // ========================================================================
    function addBackToTopButton() {
        const backToTopButton = document.createElement('button');
        backToTopButton.className = 'back-to-top';
        backToTopButton.innerHTML = '⬆️';
        backToTopButton.title = 'Back to top';
        backToTopButton.style.display = 'none';
        
        document.body.appendChild(backToTopButton);
        
        // Show/hide button based on scroll position
        window.addEventListener('scroll', function() {
            if (window.pageYOffset > 300) {
                backToTopButton.style.display = 'block';
            } else {
                backToTopButton.style.display = 'none';
            }
        });
        
        // Scroll to top when clicked
        backToTopButton.addEventListener('click', function() {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }
    
    // ========================================================================
    // MODULE STATUS INDICATORS
    // ========================================================================
    function addModuleStatusIndicators() {
        const moduleLinks = document.querySelectorAll('a[href*="modules/"]');
        
        moduleLinks.forEach(link => {
            const statusBadge = document.createElement('span');
            statusBadge.className = 'module-status status-stable';
            statusBadge.textContent = '✅ Stable';
            
            link.parentNode.insertBefore(statusBadge, link.nextSibling);
        });
    }
    
    // ========================================================================
    // INITIALIZE ALL FEATURES
    // ========================================================================
    
    // Only generate TOC for module pages
    if (window.location.pathname.includes('/modules/')) {
        generateTableOfContents();
    }
    
    enhanceCodeBlocks();
    addSearchFunctionality();
    enableSmoothScrolling();
    addBackToTopButton();
    addModuleStatusIndicators();
    
    console.log('📚 CloudWalker Infrastructure Documentation loaded successfully!');
});

// ============================================================================
// CSS STYLES FOR JAVASCRIPT FEATURES
// ============================================================================
const styles = `
    .table-of-contents {
        background: #f8f9fa;
        border: 1px solid #e9ecef;
        border-radius: 0.5rem;
        padding: 1rem;
        margin: 1rem 0;
    }
    
    .table-of-contents ul {
        list-style: none;
        padding-left: 0;
    }
    
    .table-of-contents li {
        margin: 0.25rem 0;
    }
    
    .table-of-contents a {
        text-decoration: none;
        color: #0366d6;
        padding: 0.25rem 0;
        display: block;
    }
    
    .table-of-contents a:hover {
        background: #e9ecef;
        padding-left: 0.5rem;
        border-radius: 0.25rem;
    }
    
    .toc-h3 { padding-left: 1rem; }
    .toc-h4 { padding-left: 2rem; }
    
    .code-block-wrapper {
        position: relative;
    }
    
    .copy-button {
        position: absolute;
        top: 0.5rem;
        right: 0.5rem;
        background: #6c757d;
        color: white;
        border: none;
        border-radius: 0.25rem;
        padding: 0.25rem 0.5rem;
        font-size: 0.75rem;
        cursor: pointer;
        transition: background 0.2s;
    }
    
    .copy-button:hover {
        background: #5a6268;
    }
    
    .search-container {
        margin-left: auto;
        position: relative;
    }
    
    .search-box {
        position: relative;
    }
    
    #search-input {
        padding: 0.5rem;
        border: 1px solid rgba(255,255,255,0.3);
        border-radius: 0.25rem;
        background: rgba(255,255,255,0.1);
        color: white;
        width: 250px;
    }
    
    #search-input::placeholder {
        color: rgba(255,255,255,0.7);
    }
    
    .search-results {
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: white;
        border: 1px solid #e9ecef;
        border-radius: 0.25rem;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        max-height: 300px;
        overflow-y: auto;
        z-index: 1000;
        display: none;
    }
    
    .search-result {
        padding: 0.75rem;
        border-bottom: 1px solid #e9ecef;
        cursor: pointer;
    }
    
    .search-result:hover {
        background: #f8f9fa;
    }
    
    .result-heading {
        font-weight: 600;
        color: #0366d6;
        font-size: 0.875rem;
    }
    
    .result-text {
        color: #6c757d;
        font-size: 0.75rem;
        margin-top: 0.25rem;
    }
    
    .no-results {
        padding: 1rem;
        text-align: center;
        color: #6c757d;
    }
    
    .back-to-top {
        position: fixed;
        bottom: 2rem;
        right: 2rem;
        background: #0366d6;
        color: white;
        border: none;
        border-radius: 50%;
        width: 3rem;
        height: 3rem;
        font-size: 1.25rem;
        cursor: pointer;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        transition: all 0.3s;
        z-index: 1000;
    }
    
    .back-to-top:hover {
        background: #0256cc;
        transform: translateY(-2px);
    }
    
    mark {
        background: #fff3cd;
        padding: 0.125rem;
        border-radius: 0.125rem;
    }
`;

// Inject styles
const styleSheet = document.createElement('style');
styleSheet.textContent = styles;
document.head.appendChild(styleSheet);