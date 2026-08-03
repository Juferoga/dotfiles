#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const projectPath = process.argv[2] || '.';
const ignoreFiles = ['.editorconfig', '.gitignore', 'README.md', 'Dockerfile', 'nginx.conf'];
const vitalFolders = ['core', 'modules', 'pages', 'shared'];

function getLogic(content, filePath) {
    let logic = "";
    // Extraer inyecciones
    const injects = content.match(/inject\(([^)]+)\)/g);
    if (injects) logic += `>inj:${injects.map(i => i.replace(/[inject()]/g, '')).join(',')}`;
    
    // Extraer rutas si es un archivo de rutas
    if (filePath.includes('.routes.ts')) {
        const routes = content.match(/path:\s*'([^']+)'/g);
        if (routes) logic += `>rt:${routes.map(r => r.split("'")[1]).join('|')}`;
    }
    return logic;
}

function scan(dir, depth = 0) {
    const files = fs.readdirSync(dir);
    let out = "";

    files.forEach(file => {
        const fullPath = path.join(dir, file);
        if (ignoreFiles.includes(file) || file.startsWith('.') || file.includes('node_modules')) return;

        const isDir = fs.statSync(fullPath).isDirectory();
        const ext = path.extname(file);

        if (isDir) {
            // Solo profundizar si es carpeta vital o estamos en niveles superiores
            if (depth < 2 || vitalFolders.some(vf => fullPath.includes(vf))) {
                const child = scan(fullPath, depth + 1);
                if (child) out += `${" ".repeat(depth)}[d]${file}\n${child}`;
            }
        } else if (['.ts', '.html'].includes(ext)) {
            const content = fs.readFileSync(fullPath, 'utf8');
            const logic = getLogic(content, fullPath);
            out += `${" ".repeat(depth)}[f]${file}${logic}\n`;
        }
    });
    return out;
}

console.log(scan(projectPath));
