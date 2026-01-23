#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Read settings from fetcher.example.json in the same folder
const settingsPath = path.join(__dirname, 'fetcher.json');
if (!fs.existsSync(settingsPath)) {
    console.error('fetcher.example.json not found in the current directory.');
    process.exit(1);
}

const arg1 = process.argv[2];

console.log(arg1);

// console.log('Execution halted.');
// process.exit(0);


let settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));

if(!arg1 in settings){
    process.exit(0);
}

settings = settings[arg1];


// process.exit(0)

const url = settings.url[5];
const method = settings.method || 'GET';
const headers = settings.headers || {};
const body = settings.body;
const fetcher = settings.fetcher || '';

const {processData} = require(`./fetchers/${fetcher}.js`);

if (!url) {
    console.error('No "url" found in fetcher.example.json.');
    process.exit(1);
}

// Node.js 18+ native fetch
fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined
})
    .then(res => res.text())
    .then(async data => {
        if(fetcher == ''){
            console.log(data)
        } else {
            await processData(data)
        }
    })
    .catch(err => {
        console.error('Fetch error:', err.message);
    });