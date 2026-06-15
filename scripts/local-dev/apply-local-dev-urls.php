<?php
// Applies 005-set-localhost-urls.sql via the web container's DB connection.
// Called automatically by entrypoint.sh when LOCAL_DB_MODE=1.
// Reads DB credentials from app/etc/local.xml.
// Respects LOCAL_BASE_URL env var; defaults to http://localhost:8080/

$localBaseUrl = getenv('LOCAL_BASE_URL') ?: getenv('MMS_BASE_URL') ?: 'http://localhost:8080/';

$xml = simplexml_load_file(__DIR__ . '/../../app/etc/local.xml');
$c   = $xml->global->resources->default_setup->connection;
$pdo = new PDO(
    sprintf('mysql:host=%s;dbname=%s;charset=utf8', $c->host, $c->dbname),
    (string) $c->username,
    (string) $c->password,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$sql = file_get_contents(__DIR__ . '/006-set-localhost-urls-new.sql');
$sql = str_replace('http://localhost:8080/', $localBaseUrl, $sql);
$sql = preg_replace('/--[^\n]*/', '', $sql);
foreach (array_filter(array_map('trim', explode(';', $sql))) as $stmt) {
    $pdo->exec($stmt);
}

echo "entrypoint: local dev URLs applied ({$localBaseUrl}).\n";
