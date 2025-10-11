// Auto-reload script for OpenSlides autologin  
// This is served by the autologin service but needs to be loaded by OpenSlides
// Add this script to OpenSlides index.html: <script src="https://slides.uso-ev.de/autologin/reload-check.js"></script>
(function() {
    'use strict';
    
    // Check URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('_autologin') === '1') {
        console.log('[Autologin] First load detected, scheduling reload...');
        
        // Remove the parameter and reload after a brief delay
        setTimeout(function() {
            const url = new URL(window.location.href);
            url.searchParams.delete('_autologin');
            window.location.replace(url.toString());
            
            // Force reload
            setTimeout(() => window.location.reload(), 100);
        }, 800);
        return;
    }
    
    // Also check localStorage flag (set by redirect.html)
    const reloadFlag = localStorage.getItem('os_trigger_reload');
    if (reloadFlag && (Date.now() - parseInt(reloadFlag)) < 5000) {
        console.log('[Autologin] Reload flag detected, reloading page...');
        localStorage.removeItem('os_trigger_reload');
        
        setTimeout(function() {
            window.location.reload(true);
        }, 500);
    }
})();
