const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else { 
            if (file.endsWith('.dart')) results.push(file);
        }
    });
    return results;
}

const files = walk('./lib/screens');
let modifiedCount = 0;

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let original = content;
    
    // 1. Replace static const String baseUrl = '...'
    content = content.replace(/static const String baseUrl = 'http:\/\/localhost:5000\/api';/g, 'static String baseUrl = ApiService.baseUrl;');
    content = content.replace(/static const String apiUrl = 'http:\/\/localhost:5000\/api\/students';/g, "static String apiUrl = '${ApiService.baseUrl}/students';");
    
    // 2. Replace inline URLs
    content = content.replace(/'http:\/\/localhost:5000\/api/g, "ApiService.baseUrl + '");
    // Some are in string interpolation like 'http://localhost:5000/api/students/${id}'
    content = content.replace(/http:\/\/localhost:5000\/api/g, '${ApiService.baseUrl}');

    if (content !== original) {
        // If ApiService is not imported, add it
        if (!content.includes('api_service.dart')) {
            content = "import 'package:school_management_app/services/api_service.dart';\n" + content;
        }
        
        fs.writeFileSync(file, content, 'utf8');
        console.log('Updated:', file);
        modifiedCount++;
    }
});

console.log(`Refactored URLs in ${modifiedCount} files.`);
