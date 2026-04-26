#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const fetchersDir = path.join(__dirname, 'fetchers');

// Ensure fetchers directory exists
if (!fs.existsSync(fetchersDir)) {
    fs.mkdirSync(fetchersDir, { recursive: true });
}

const arg1 = process.argv[2];
const arg2 = process.argv[3];

if (arg1 === '--init') {
    const name = arg2;
    if (!name) {
        console.error('Please provide a name for the fetcher: fetchers --init <name>');
        process.exit(1);
    }

    const dirPath = path.join(fetchersDir, name);
    const jsonPath = path.join(dirPath, `${name}.json`);
    const jsPath = path.join(dirPath, `${name}.js`);

    if (fs.existsSync(dirPath)) {
        console.error(`Fetcher "${name}" already exists.`);
        process.exit(1);
    }

    fs.mkdirSync(dirPath, { recursive: true });

    const defaultConfig = {
        "url": ["https://www.google.com"],
        "method": "GET",
        "headers": {
            "Content-Type": "",
            "Authorization": "",
            "Cookie": "",
            "User-Agent": "Mozilla/5.0",
            "Accept": "*/*",
            "X-Custom-Header": ""
        },
        "body": null
    };

    const defaultJs = `
/**
 * Process the data returned from the fetch request.
 * @param {string} data - The raw response text.
 */
exports.processData = async (data) => {
    try {
        const json = JSON.parse(data);
        console.log(JSON.stringify(json, null, 2));
    } catch (e) {
        console.log(data);
    }
};
`;

    fs.writeFileSync(jsonPath, JSON.stringify(defaultConfig, null, 2));
    fs.writeFileSync(jsPath, defaultJs.trim() + '\n');

    console.log(`Fetcher "${name}" initialized in ${dirPath}`);
    process.exit(0);
}

// List fetchers if no argument or help
if (!arg1 || arg1 === '--help' || arg1 === '-h') {
    const items = fs.readdirSync(fetchersDir, { withFileTypes: true });
    const fetchers = items
        .filter(item => item.isDirectory())
        .map(item => item.name);

    console.log('Usage: fetchers <name> | --init <name>');
    if (fetchers.length > 0) {
        console.log('Available fetchers:', fetchers.join(', '));
    } else {
        console.log('No fetchers found. Create one with: fetchers --init <name>');
    }
    process.exit(arg1 ? 0 : 1);
}

const name = arg1;
const dirPath = path.join(fetchersDir, name);
const jsonPath = path.join(dirPath, `${name}.json`);
const jsPath = path.join(dirPath, `${name}.js`);

if (!fs.existsSync(jsonPath)) {
    console.error(`Fetcher "${name}" not found (expected ${jsonPath})`);
    process.exit(1);
}

let settings;
try {
    settings = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
} catch (e) {
    console.error(`Error parsing ${jsonPath}:`, e.message);
    process.exit(1);
}

const url = Array.isArray(settings.url) ? settings.url[0] : settings.url;
const method = settings.method || 'GET';
const headers = settings.headers || {};
const body = settings.body;

let processData;
if (fs.existsSync(jsPath)) {
    try {
        const module = require(jsPath);
        processData = module.processData;
    } catch (e) {
        console.error(`Error loading ${jsPath}:`, e.message);
    }
}

if (!url) {
    console.error(`No "url" found in ${jsonPath}`);
    process.exit(1);
}

// Node.js 18+ native fetch
fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
})
    .then(res => {
        if (!res.ok) {
            console.warn(`Response not OK: ${res.status} ${res.statusText}`);
        }
        return res.text();
    })
    .then(async data => {
        if (typeof processData === 'function') {
            await processData(data);
        } else {
            console.log(data);
        }
    })
    .catch(err => {
        console.error('Fetch error:', err.message);
    });
