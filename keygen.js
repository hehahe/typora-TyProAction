module.exports = async ({
  github,
  context,
  core,
  KEYGEN_JS_CODE
}) => {
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

  if (context.payload.issue.title === 'keygen') {
    try {
      const info = context.payload.issue.body;
      const commMatch = info.replace(/\r/g, '').match(/<!--.+-->/s);

      if (commMatch) {
        const conf = commMatch[0].split('\n').filter(i => !i.match(/：|<!--|-->/));

        if (conf.length === 3) {
          const key = KEYGEN_JS_CODE(...conf);
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
