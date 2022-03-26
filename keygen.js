module.exports = async ({
  github,
  context,
  core,
  KEYGEN_JS_CODE,
  PRIVATE_KEY
}) => {
  const crypto = require('crypto');
  async function endWithComment(words, isok) {
    await github.rest.issues.createComment({
      issue_number: context.issue.number,
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: words || '指令匹配错误\n\ncommand match error'
    });
    await github.rest.issues.update({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: context.issue.number,
      state: 'closed',
      labels: [isok ? '☑️keygen/注册机🎉' : '🤔invalid/无效的😒']
    });
    return;
  }
  function encode (MachineCode,email,license){
    var Base64={table:["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"],UTF16ToUTF8:function(r){for(var e=[],t=r.length,h=0;h<t;h++){var o=r.charCodeAt(h);if(o>0&&o<=127)e.push(r.charAt(h));else if(o>=128&&o<=2047){var a=192|o>>6&31,i=128|63&o;e.push(String.fromCharCode(a),String.fromCharCode(i))}else if(o>=2048&&o<=65535){a=224|o>>12&15,i=128|o>>6&63;var c=128|63&o;e.push(String.fromCharCode(a),String.fromCharCode(i),String.fromCharCode(c))}}return e.join("")},UTF8ToUTF16:function(r){var e=[],t=r.length,h=0;for(h=0;h<t;h++){var o=r.charCodeAt(h);if(0==(o>>7&255))e.push(r.charAt(h));else if(6==(o>>5&255)){var a=(31&o)<<6|63&(i=r.charCodeAt(++h));e.push(Sting.fromCharCode(a))}else if(14==(o>>4&255)){var i;a=(255&(o<<4|(i=r.charCodeAt(++h))>>2&15))<<8|((3&i)<<6|63&r.charCodeAt(++h));e.push(String.fromCharCode(a))}}return e.join("")},encode:function(r){if(!r)return"";for(var e=this.UTF16ToUTF8(r),t=0,h=e.length,o=[];t<h;){var a=255&e.charCodeAt(t++);if(o.push(this.table[a>>2]),t==h){o.push(this.table[(3&a)<<4]),o.push("==");break}var i=e.charCodeAt(t++);if(t==h){o.push(this.table[(3&a)<<4|i>>4&15]),o.push(this.table[(15&i)<<2]),o.push("=");break}var c=e.charCodeAt(t++);o.push(this.table[(3&a)<<4|i>>4&15]),o.push(this.table[(15&i)<<2|(192&c)>>6]),o.push(this.table[63&c])}return o.join("")},decode:function(r){if(!r)return"";for(var e=r.length,t=0,h=[];t<e;)code1=this.table.indexOf(r.charAt(t++)),code2=this.table.indexOf(r.charAt(t++)),code3=this.table.indexOf(r.charAt(t++)),code4=this.table.indexOf(r.charAt(t++)),c1=code1<<2|code2>>4,c2=(15&code2)<<4|code3>>2,c3=(3&code3)<<6|code4,h.push(String.fromCharCode(c1)),64!=code3&&h.push(String.fromCharCode(c2)),64!=code4&&h.push(String.fromCharCode(c3));return this.UTF8ToUTF16(h.join(""))}};
    var mc=JSON.parse(Base64.decode(MachineCode));
    var signInfo={fingerprint: mc.i, email , license, type: '1'};
    return JSON.stringify(signInfo);
  }
  if (context.payload.issue.title === 'keygen') {
    try {
      const info = context.payload.issue.body;
      const commMatch = info.replace(/\r/g, '').match(/<!--.+-->/s);

      if (commMatch) {
        const conf = commMatch[0].split('\n').filter(i => !i.match(/：|<!--|-->/));

        if (conf.length === 3) {
//           const key = KEYGEN_JS_CODE(...conf);
          console.log(crypto);
          const encodeData2 = crypto.privateEncrypt(PRIVATE_KEY, Buffer.from(encode(...conf))).toString('base64');
//           console.log("encode2: ", encodeData2)
          const key=encodeData2;
          await endWithComment(`您的离线激活码为/Your offline activation code is:

\`+${key}\`

---

最好在\`host\`中添加如下拦截，以防联网检测（懒，未删除该部分内容）

It is best to add the following interception to the \`host\` to prevent network detection (cause of lazy, this part of the content did not deleted)

\`\`\`
0.0.0.0 store.typora.io
0.0.0.0 dian.typora.com.cn
0.0.0.0 typora.com.cn
\`\`\``, true);
          return
        }
      }

      await endWithComment('无法正确匹配到配置信息\n\nCan not match the configuration information correctly.');
      return;
    } catch (error) {
      await endWithComment('激活码计算过程中发生错误\n\nAn error occurred during activation code calculation');
      return
    }
  } else {
    await endWithComment();
  }
};
