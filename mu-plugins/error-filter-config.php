<?php
/**
 * Error Filter Configuration
 * Modify these settings to customize error filtering behavior
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// Configuration constants for the error filter
define('ERROR_FILTER_CACHE_DURATION', 24 * 60 * 60); // 24 hours in seconds

// Define which error types to filter (set to false to disable filtering for that type)
define('ERROR_FILTER_NOTICES', true);      // Filter E_NOTICE and E_USER_NOTICE
define('ERROR_FILTER_WARNINGS', true);     // Filter E_WARNING and E_USER_WARNING  
define('ERROR_FILTER_DEPRECATED', true);   // Filter E_DEPRECATED and E_USER_DEPRECATED

// Advanced settings
define('ERROR_FILTER_MAX_CACHE_ENTRIES', 1000); // Maximum number of cached error hashes
define('ERROR_FILTER_CLEANUP_INTERVAL', 60 * 60); // Clean cache every hour

// Specific message patterns to always filter (regex patterns)
$ERROR_FILTER_BLACKLIST = array(
    '/Function _load_textdomain_just_in_time was called.*incorrectly/',
    '/Translation loading for the.*domain was triggered too early/',
    // Add more patterns here as needed
    // '/your_pattern_here/',
);

// Specific message patterns to never filter (always log these)
$ERROR_FILTER_WHITELIST = array(
    '/Fatal error/',
    '/Parse error/',
    '/Call to undefined function/',
    // Add critical error patterns here
);

// Enable detailed logging of filter activity (for debugging the filter itself)
define('ERROR_FILTER_DEBUG', false);