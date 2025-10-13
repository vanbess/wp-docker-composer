<?php
/**
 * Custom Error Filter for WordPress
 * Prevents log spamming by filtering duplicate notices/warnings
 * Only logs the same message again after 24 hours
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// Load configuration
require_once __DIR__ . '/error-filter-config.php';

class CustomErrorFilter {
    
    private $log_file;
    private $cache_file;
    private $cache_duration;
    private $message_cache = array();
    
    public function __construct() {
        $this->log_file = WP_CONTENT_DIR . '/debug.log';
        $this->cache_file = WP_CONTENT_DIR . '/debug-cache.json';
        $this->cache_duration = defined('ERROR_FILTER_CACHE_DURATION') ? ERROR_FILTER_CACHE_DURATION : 86400;
        $this->load_cache();
        $this->setup_error_handler();
    }
    
    /**
     * Load message cache from file
     */
    private function load_cache() {
        if (file_exists($this->cache_file)) {
            $cache_data = file_get_contents($this->cache_file);
            $this->message_cache = json_decode($cache_data, true) ?: array();
            
            // Clean up expired entries
            $this->cleanup_cache();
        }
    }
    
    /**
     * Save message cache to file
     */
    private function save_cache() {
        file_put_contents($this->cache_file, json_encode($this->message_cache));
    }
    
    /**
     * Remove expired cache entries
     */
    private function cleanup_cache() {
        $current_time = time();
        foreach ($this->message_cache as $hash => $timestamp) {
            if ($current_time - $timestamp > $this->cache_duration) {
                unset($this->message_cache[$hash]);
            }
        }
    }
    
    /**
     * Setup custom error handler
     */
    private function setup_error_handler() {
        // Set custom error handler
        set_error_handler(array($this, 'custom_error_handler'));
        
        // Also filter WordPress debug logging
        add_filter('wp_debug_backtrace_summary', array($this, 'filter_wp_debug'), 10, 4);
    }
    
    /**
     * Custom error handler that filters duplicate messages
     */
    public function custom_error_handler($errno, $errstr, $errfile, $errline) {
        
        // Define which error types to filter based on configuration
        $filtered_types = array();
        
        if (defined('ERROR_FILTER_NOTICES') && ERROR_FILTER_NOTICES) {
            $filtered_types[] = E_NOTICE;
            $filtered_types[] = E_USER_NOTICE;
        }
        
        if (defined('ERROR_FILTER_WARNINGS') && ERROR_FILTER_WARNINGS) {
            $filtered_types[] = E_WARNING;
            $filtered_types[] = E_USER_WARNING;
        }
        
        if (defined('ERROR_FILTER_DEPRECATED') && ERROR_FILTER_DEPRECATED) {
            $filtered_types[] = E_DEPRECATED;
            $filtered_types[] = E_USER_DEPRECATED;
        }
        
        // Only filter specific error types
        if (!in_array($errno, $filtered_types)) {
            return false; // Let PHP handle fatal errors, parse errors, etc.
        }
        
        // Check whitelist patterns (never filter these)
        global $ERROR_FILTER_WHITELIST;
        if (!empty($ERROR_FILTER_WHITELIST)) {
            foreach ($ERROR_FILTER_WHITELIST as $pattern) {
                if (preg_match($pattern, $errstr)) {
                    return false; // Don't filter, let it log
                }
            }
        }
        
        // Check blacklist patterns (always filter these)
        global $ERROR_FILTER_BLACKLIST;
        if (!empty($ERROR_FILTER_BLACKLIST)) {
            foreach ($ERROR_FILTER_BLACKLIST as $pattern) {
                if (preg_match($pattern, $errstr)) {
                    return true; // Always suppress these
                }
            }
        }
        
        // Create a unique hash for this error message
        $message_hash = md5($errstr . $errfile . $errline);
        $current_time = time();
        
        // Check if we've seen this message recently
        if (isset($this->message_cache[$message_hash])) {
            $last_logged = $this->message_cache[$message_hash];
            
            // If it's been less than 24 hours, don't log it
            if ($current_time - $last_logged < $this->cache_duration) {
                return true; // Suppress the error
            }
        }
        
        // Log this message and update cache
        $this->message_cache[$message_hash] = $current_time;
        $this->save_cache();
        
        // Format the error message
        $error_types = array(
            E_ERROR => 'Fatal Error',
            E_WARNING => 'Warning',
            E_PARSE => 'Parse Error',
            E_NOTICE => 'Notice',
            E_CORE_ERROR => 'Core Error',
            E_CORE_WARNING => 'Core Warning',
            E_COMPILE_ERROR => 'Compile Error',
            E_COMPILE_WARNING => 'Compile Warning',
            E_USER_ERROR => 'User Error',
            E_USER_WARNING => 'User Warning',
            E_USER_NOTICE => 'User Notice',
            E_DEPRECATED => 'Deprecated',
            E_USER_DEPRECATED => 'User Deprecated'
        );
        
        $error_type = isset($error_types[$errno]) ? $error_types[$errno] : 'Unknown Error';
        $log_message = sprintf(
            "[%s] PHP %s: %s in %s on line %d\n",
            date('d-M-Y H:i:s T'),
            $error_type,
            $errstr,
            $errfile,
            $errline
        );
        
        // Write to debug log
        if (defined('WP_DEBUG_LOG') && WP_DEBUG_LOG) {
            error_log($log_message, 3, $this->log_file);
        }
        
        return true; // Don't execute PHP internal error handler
    }
    
    /**
     * Filter WordPress debug messages
     */
    public function filter_wp_debug($summary, $ignore_class, $skip_frames, $pretty) {
        // This helps filter WordPress's own debug messages
        return $summary;
    }
    
    /**
     * Get statistics about filtered messages
     */
    public function get_stats() {
        $this->cleanup_cache();
        return array(
            'cached_messages' => count($this->message_cache),
            'cache_file_size' => file_exists($this->cache_file) ? filesize($this->cache_file) : 0,
            'oldest_cache_entry' => !empty($this->message_cache) ? date('Y-m-d H:i:s', min($this->message_cache)) : 'None',
        );
    }
}

// Initialize the error filter
new CustomErrorFilter();

// Add admin notice to show filter is active (only for administrators)
add_action('admin_notices', function() {
    if (current_user_can('administrator') && isset($_GET['page']) && $_GET['page'] === 'site-health') {
        echo '<div class="notice notice-info"><p><strong>Custom Error Filter Active:</strong> Duplicate notices and warnings are being filtered to prevent log spam.</p></div>';
    }
});

// Add WP-CLI command to view stats (if WP-CLI is available)
if (class_exists('WP_CLI')) {
    WP_CLI::add_command('error-filter-stats', function() {
        $filter = new CustomErrorFilter();
        $stats = $filter->get_stats();
        
        WP_CLI::success('Error Filter Statistics:');
        WP_CLI::line('Cached Messages: ' . $stats['cached_messages']);
        WP_CLI::line('Cache File Size: ' . $stats['cache_file_size'] . ' bytes');
        WP_CLI::line('Oldest Cache Entry: ' . $stats['oldest_cache_entry']);
    });
}