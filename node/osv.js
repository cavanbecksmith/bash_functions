#!/usr/bin/env node

// Simple CLI to search OSV by CVE
// Uses native fetch (Node.js 18+)

function searchOSV(cve) {
    const url = `https://api.osv.dev/v1/vulns/${cve}`;
    fetch(url)
        .then(res => res.json())
        .then(result => {
            console.log({result})
            // if (result.summary) {
            //     console.log(`CVE: ${cve}\nSummary: ${result.summary}`);
            // } else {
            //     console.log(`No results for ${cve}`);
            // }
        })
        .catch(e => {
            console.error('Request or parsing error:', e.message);
        });
}

const cve = process.argv[2];
if (!cve) {
    console.log('Usage: node osv.js <CVE-ID>');
    process.exit(1);
}
searchOSV(cve);
