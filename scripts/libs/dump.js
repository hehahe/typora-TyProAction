const Module = module.constructor;
const rawCompile = Module.prototype._compile;
const fs = require("fs");
const path = require("path");
Module.prototype._compile = function(content, filename) {
  if(filename.indexOf('app.asar') !== -1) {
    //fs.writeFileSync(path.basename(filename).replace('.js','-raw.js'), content);
    //替换公钥
    const newcontent = content.replace(/-+BEGIN PUBLIC KEY-+.+-+END PUBLIC KEY-+/s,`-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0Uj1Cvz56krcs6rVe92g
A52+k9TyMBahmrY34MlFtO/87PZl+YG0ft7j2uQs4gr9A5XkJFRbyZ9HGnBaH+g5
UvRnAZeT2Bp9JXvOm6GE9hi4FXyF98lFI509IC/jau/Bj7j/0DW87TrigCFCr4D0
oHQlu5IOk9RReLIiFUuEyBsLN58ZpFALUatKpArtGS6NwtKYTgG1mwbNNX3O2MBn
JpBTUXEWe1bwGR3e5kNUxbNJDEWEmUK8d6pYGY43aKB7H4dEC33sorNByEhBn6On
/6cjw5xDER8lSPetAEpmIHR6WsP6qtYrhD6UUcCvkNUoLoVIO9YYq/7sBWU/b7SM
VwIDAQAB
-----END PUBLIC KEY-----
`)
        //去验证
        .replace(/https:\/\/store\.typora\.io|https:\/\/dian\.typora\.com\.cn|https:\/\/typora\.com\.cn\/store\//g,'')
        //更改更新位置到本库
        .replace(/[^'"`]+releases\/windows_[^'"`]+/,a=>a.replace(/https?:\/\/[^\/]+/,"https://cdn.jsdelivr.net/gh/taozhiyu/TyProAction@main/config"))
    fs.writeFileSync(path.basename(filename), newcontent);
    console.log("Inject Success");
    process.exit(0);
  }
  return rawCompile.call(this, content, filename);
}
