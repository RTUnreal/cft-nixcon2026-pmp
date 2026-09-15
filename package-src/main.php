#!/usr/bin/env php
<?php

/**
 * Parses the contents of the target file.
 *
 * @param string $contents The raw contents of the target file.
 * @return mixed The parsed results.
 */
function parseFile(string $contents)
{
    $lines = explode("\n", $string);
    $lines = array_slice($lines, 2);
    if (preg_match('/NIXCON\{[^}]+\}/', $lines[1], $matches)) {
        return $matches[0];
    } else {
        echo "FLAG NOT FOUND";
        exit(1);
    }
}

$options = getopt("c:p", ["config:", "print-target"]);

$configFile = $options['c'] ?? $options['config'] ?? null;
$print_target = isset($options['p']) || isset($options['print-target']);

if ($configFile == null) {
    fwrite(STDERR, "Usage: php script.php -c <config.xml>\n");
    exit(1);
}

if (!file_exists($configFile) || !is_readable($configFile)) {
    fwrite(STDERR, "Error: Configuration file '{$configFile}' not found or not readable.\n");
    exit(1);
}

$xmlContent = file_get_contents($configFile);
if ($xmlContent === false) {
    fwrite(STDERR, "Error: Could not read configuration file.\n");
    exit(1);
}

$previousUseErrors = libxml_use_internal_errors(true);
try {
    $configXml = new SimpleXMLElement($xmlContent);
} catch (Exception $e){
    fwrite(STDERR, "Error: Failed to parse XML configuration file.\n");
    exit(1);
}
libxml_use_internal_errors($previousUseErrors);

$targetFile = null;

if (isset($configXml->targetFile)) {
    $targetFile = (string) $configXml->targetFile;
} elseif (isset($configXml['targetFile'])) {
    $targetFile = (string) $configXml['targetFile'];
} else {
    $nodes = $configXml->xpath('//targetFile');
    if (!empty($nodes)) {
        $targetFile = (string) $nodes[0];
    }
}

if ($targetFile === null || $targetFile === '') {
    fwrite(STDERR, "Error: 'targetFile' key not found in the XML configuration.\n");
    exit(1);
}

if ($print_target) {
    echo $targetFile;
    exit(0);
}

if (!file_exists($targetFile) || !is_readable($targetFile)) {
    fwrite(STDERR, "Error: Target file '{$targetFile}' not found or not readable.\n");
    exit(1);
}

$targetContents = file_get_contents($targetFile);
if ($targetContents === false) {
    fwrite(STDERR, "Error: Could not read target file '{$targetFile}'.\n");
    exit(1);
}

$results = parseFile($targetContents);

echo $results . "\n";
