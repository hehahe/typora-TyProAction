module.exports = async ({ github, context, crypto, PRIVATE_KEY }) => {
    async function endWithComment(words, isOk) {
        await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: words || '指令匹配错误\n\ncommand match error',
        });
        await github.rest.issues.update({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: context.issue.number,
            state: 'closed',
            labels: [isOk ? '☑️keygen/注册机🎉' : '🤔invalid/无效的😒'],
        });
        return;
    }
    function doEnc(MachineCode, email, license) {
        var mc = JSON.parse(Buffer.from(MachineCode, 'base64').toString());
        var signInfo = { fingerprint: mc.i, email, license, type: '1' };
        return JSON.stringify(signInfo);
    }
    if (
        JSON.stringify(context.payload.issue.labels).includes('🔧Config/配置⚙️')
    )
        return;
    if (
        JSON.stringify(context.payload.issue.labels).includes(
            '🐛bug report/反馈🐛'
        )
    ) {
        await github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: '匹配到 `bug` 标签，很抱歉为您带来困扰。请耐心等待作者查看回复\n\nFound the `bug` tag, so sorry for the inconvenience. Please wait patiently for the author to view and reply',
        });
        return;
    }
    if (context.payload.issue.title.toLowerCase() === 'keygen') {
        try {
            const commMatch = context.payload.issue.body
                .split('###')
                .filter(a => a.match(/机器码|用户名|激活码|activationCode|machineCode|userName/))
                .map(a =>
                    a.replace(/\r|\n| +|<!--|-->|机器码|用户名|激活码|activationCode|machineCode|userName/g, '')
                );

            if (commMatch && commMatch.length === 3) {
                const code = doEnc(...commMatch);
                const key = crypto
                    .privateEncrypt(PRIVATE_KEY, Buffer.from(code))
                    .toString('base64');
                await endWithComment(
                    `您的离线激活码为/Your offline activation code is:

\`+${key}\`

---
请先在[release](https://github.com/taozhiyu/TyProAction/releases)中下载并覆盖替换补丁文件

Please download and overwrite the patch in [**release**](https://github.com/taozhiyu/TyProAction/releases) first

我们从代码中移除了相关的检测，无需再修改 Host

We removed the relevant detection from the code, NO need to modify the Host anymore.`,
                    true
                );
                return;
            }

            await endWithComment(
                '无法正确匹配到配置信息\n\nCAN NOT match the configuration information correctly.'
            );
            return;
        } catch (error) {
            console.log(error);
            await endWithComment(
                '激活码计算过程中发生错误\n\nAn error occurred during activation code calculation'
            );
            return;
        }
    } else {
        await endWithComment();
    }
};
