const fs = require('fs');
const path = require('path');
module.exports = async ({
    github,
    context,
    core,
    checkType,
    update_version,
    forceVersion,
    forceUpdate,
}) => {
    isDev = forceVersion ? forceVersion.endsWith('-dev') : checkType === 'dev';
    console.log(isDev ? '开发版' : '稳定版');
    update_version = forceVersion ? forceVersion : update_version;
    const exePath = path.resolve('Typro-update-V' + update_version + '.exe');
    const win64ConfigPath = path.resolve(
        `config/releases/${isDev ? 'dev_' : ''}windows_64.json`
    );
    const asarZip = path.resolve('asar-file-V' + update_version + '.zip');

    //发布新release
    const releaseInfo = await github.rest.repos.createRelease({
        owner: context.repo.owner,
        repo: context.repo.repo,
        tag_name: 'v'+update_version,
        name: 'v' + update_version,
        body:
            'TyproAction ' +(forceVersion?'Manual trigger ':'auto ')+'update success!\n\n- [x] Update time: ' +
            new Date().toUTCString(),
        prerelease: isDev,
    });
    //console.log(releaseInfo);

    const assetInfo = await github.rest.repos.uploadReleaseAsset({
        owner: context.repo.owner,
        repo: context.repo.repo,
        release_id: releaseInfo.data.id,
        name: 'Typro-Update-V' + update_version + '.exe',
        data: fs.readFileSync(exePath),
    });
    //console.log(assetInfo);

    const assetInfo2 = await github.rest.repos.uploadReleaseAsset({
        owner: context.repo.owner,
        repo: context.repo.repo,
        release_id: releaseInfo.data.id,
        name: 'asar-file-V' + update_version + '.zip',
        data: fs.readFileSync(asarZip),
    });
    //console.log(assetInfo2);

    //更新json配置
    if (!(forceVersion && forceUpdate !== '1')) {
        const conf = JSON.parse(fs.readFileSync(win64ConfigPath));
        console.log(conf);
        conf.version = update_version;
        conf.download = assetInfo.data.browser_download_url;
        conf.downloadCN = assetInfo.data.browser_download_url.replace("github.com","hub.fastgit.xyz");
        if (isDev) conf.download = conf.downloadCN;
        fs.writeFileSync(win64ConfigPath, JSON.stringify(conf, '', 4));
    }
    //删除缓存文件
    fs.unlinkSync(exePath);
    fs.unlinkSync(asarZip);

    core.setOutput('commit_message', `update ${checkType} V${update_version}`);
};
