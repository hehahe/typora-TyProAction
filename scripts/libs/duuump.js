const Module = require('module');
const oldCompile = Module.prototype._compile;
Module.prototype._compile = function (content, filename) {
    if (filename.endsWith('atom.js'))
        content = content
            .replace(
                /-+BEGIN PUBLIC KEY-+.+-+END PUBLIC KEY-+/s,
                `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0Uj1Cvz56krcs6rVe92g
A52+k9TyMBahmrY34MlFtO/87PZl+YG0ft7j2uQs4gr9A5XkJFRbyZ9HGnBaH+g5
UvRnAZeT2Bp9JXvOm6GE9hi4FXyF98lFI509IC/jau/Bj7j/0DW87TrigCFCr4D0
oHQlu5IOk9RReLIiFUuEyBsLN58ZpFALUatKpArtGS6NwtKYTgG1mwbNNX3O2MBn
JpBTUXEWe1bwGR3e5kNUxbNJDEWEmUK8d6pYGY43aKB7H4dEC33sorNByEhBn6On
/6cjw5xDER8lSPetAEpmIHR6WsP6qtYrhD6UUcCvkNUoLoVIO9YYq/7sBWU/b7SM
VwIDAQAB
-----END PUBLIC KEY-----`
            )
            .replace(
                /https:\/\/store\.ty\u0070ora\.io|https:\/\/dian\.ty\u0070ora\.com\.cn|https:\/\/ty\u0070ora\.com\.cn\/store\//g,
                ''
            )
            .replace(
                /\$\{[^}]+}\/releases\/(dev_)?windows_/g,
                'taozhiyu.github.io/TyProAction/config/releases/$1windows_'
            )
            .replace(/ty\u0070ora-update-["+\w.-]+-"/g, 'Typro-Update-V"');
    return oldCompile.call(this, content, filename);
};
// process.argv.length = 1;
require('./main.node');
