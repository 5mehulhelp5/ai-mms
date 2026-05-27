<?php
/**
 * Catalog Search spam detection — bucket catalog.
 *
 * Each bucket is a deterministic SQL predicate against catalogsearch_query.
 * Buckets never match rows that have an admin-curated `synonym_for` or
 * `redirect` value, so curated entries are protected from bulk deletion.
 */
class MMD_Adminhtml_Helper_SearchSpam extends Mage_Core_Helper_Abstract
{
    /** Programming-language single-letter terms that are NOT spam. */
    public const KEEP_SINGLE_CHARS = array('R', 'C');

    /** English stopwords with no catalog value. */
    public const STOPWORDS = array(
        'the', 'a', 'an', 'of', 'in', 'is', 'and', 'or', 'to', 'for',
        'with', 'on', 'at', 'by', 'as', 'it', 'this', 'that', 'be',
        'are', 'was', 'were', 'have', 'has', 'i', 'you', 'he', 'she',
        'we', 'they', 'do', 'does', 'did', 'so', 'if', 'but', 'not',
    );

    /**
     * @return array<int, array{id:string,label:string,description:string,where:string}>
     */
    public function getBuckets()
    {
        $keepChars = "'" . implode("','", array_merge(
            self::KEEP_SINGLE_CHARS,
            array_map('strtolower', self::KEEP_SINGLE_CHARS)
        )) . "'";

        $stopwords = "'" . implode("','", self::STOPWORDS) . "'";

        return array(
            array(
                'id'          => 'empty',
                'label'       => 'Empty / whitespace queries',
                'description' => 'query_text is empty after trimming.',
                'where'       => "TRIM(query_text) = ''",
            ),
            array(
                'id'          => 'single_char',
                'label'       => 'Single-character queries',
                'description' => 'One character only (e.g. "e", "1") — excludes "R" and "C" which are programming languages.',
                'where'       => "CHAR_LENGTH(TRIM(query_text)) = 1 AND TRIM(query_text) NOT IN ($keepChars)",
            ),
            array(
                'id'          => 'numeric_only',
                'label'       => 'Numeric-only queries',
                'description' => 'Pure digits (e.g. "1", "2024"). Not useful as a search term.',
                'where'       => "query_text REGEXP '^[0-9]+$'",
            ),
            array(
                'id'          => 'stopwords',
                'label'       => 'English stopwords',
                'description' => '"the", "a", "of", etc. — high popularity but no catalog signal.',
                'where'       => "LOWER(TRIM(query_text)) IN ($stopwords)",
            ),
            array(
                'id'          => 'very_long',
                'label'       => 'Very long queries (>100 chars)',
                'description' => 'Pasted essays, bot fingerprints, or injection attempts.',
                'where'       => "CHAR_LENGTH(query_text) > 100",
            ),
            array(
                'id'          => 'contains_url',
                'label'       => 'Contains a URL',
                'description' => 'Bot SEO spam — search terms containing http://, https://, or www.',
                'where'       => "LOWER(query_text) REGEXP 'https?://|www\\\\.'",
            ),
            array(
                'id'          => 'html_or_script',
                'label'       => 'HTML / script tags',
                'description' => 'Cross-site-scripting probes — contain "<", ">", "script", "onerror", or "alert(".',
                'where'       => "(query_text LIKE '%<%' OR query_text LIKE '%>%' OR LOWER(query_text) LIKE '%script%' OR LOWER(query_text) LIKE '%onerror%' OR LOWER(query_text) LIKE '%alert(%')",
            ),
            array(
                'id'          => 'sql_injection',
                'label'       => 'SQL-injection patterns',
                'description' => 'Probes containing "union select", "drop table", SQL comments, etc.',
                'where'       => "(LOWER(query_text) REGEXP 'union[[:space:]]+select|drop[[:space:]]+table' OR query_text LIKE '%/*%' OR query_text LIKE '%-- %')",
            ),
            array(
                'id'          => 'control_chars',
                'label'       => 'Control characters',
                'description' => 'Contains non-printable / control characters (binary garbage).',
                'where'       => "query_text REGEXP '[[:cntrl:]]'",
            ),
            array(
                'id'          => 'zero_results_one_off',
                'label'       => 'Zero-result, one-off queries',
                'description' => 'num_results = 0 AND popularity = 1. The long-tail of failed one-time searches that clogs the table.',
                'where'       => "num_results = 0 AND popularity <= 1",
            ),
        );
    }

    /**
     * Combine the curated-row exclusion guard with a caller-supplied predicate.
     * Used by every count/select/delete query.
     */
    public function curatedGuard()
    {
        return "(synonym_for IS NULL OR synonym_for = '') "
             . "AND (redirect IS NULL OR redirect = '')";
    }

    /**
     * Build a WHERE clause for the given bucket ids, OR'd together,
     * AND'd with the curated-row guard, AND'd with optional store filter.
     *
     * @param array<int,string> $bucketIds
     * @param int               $storeId  0 = all stores
     * @return string|null  null if no valid buckets requested
     */
    public function buildWhereForBuckets(array $bucketIds, $storeId = 0)
    {
        $byId = array();
        foreach ($this->getBuckets() as $b) {
            $byId[$b['id']] = $b['where'];
        }
        $parts = array();
        foreach ($bucketIds as $id) {
            if (isset($byId[$id])) {
                $parts[] = '(' . $byId[$id] . ')';
            }
        }
        if (empty($parts)) {
            return null;
        }
        $where = '(' . implode(' OR ', $parts) . ')'
               . ' AND ' . $this->curatedGuard();
        $storeId = (int) $storeId;
        if ($storeId > 0) {
            $where .= " AND store_id = $storeId";
        }
        return $where;
    }
}
