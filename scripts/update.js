const fs = require('fs');
const path = require('path');
module.exports = async ({ github, context }) => {
    const latestTag = (
        await github.rest.repos.listTags({
            owner: context.repo.owner,
            repo: context.repo.repo, //'TyProAction',
        })
    ).data[0]?.name;
    const latestVersion = (
        await github.request('GET https://typora.io/releases/windows_64.json')
    ).data.version;
    console.log(latestTag, latestVersion);
    //无更新
    if (latestTag && latestTag.slice(1) === latestVersion) return;

    const exePath = path.resolve('Typro-update-V' + latestVersion + '.exe');
    const win64ConfigPath = path.resolve('config/releases/windows_64.json');
    const asarZip = path.resolve('../app-file-V' + latestVersion + '.zip');

    //发布新release
    const releaseInfo = await github.rest.repos.createRelease({
        owner: context.repo.owner,
        repo: context.repo.repo, //'TyProAction',
        tag_name: 'v' + latestVersion,
        name: 'v' + latestVersion,
        body:
            'TyproAction auto update test!\n\nUpdate time: ' +
            new Date().toUTCString(),
    });
    console.log(releaseInfo);

    const assetInfo = await github.rest.repos.uploadReleaseAsset({
        owner: context.repo.owner,
        repo: context.repo.repo, //'TyProAction',
        release_id: releaseInfo.data.id,
        name: 'Typro-Update-V' + latestVersion + '.exe',
        data: fs.readFileSync(exePath),
    });
    console.log(assetInfo);

    const assetInfo2 = await github.rest.repos.uploadReleaseAsset({
        owner: context.repo.owner,
        repo: context.repo.repo, //'TyProAction',
        release_id: releaseInfo.data.id,
        name: 'asar-file-V' + latestVersion + '.zip',
        data: fs.readFileSync(asarZip),
    });
    console.log(assetInfo2);

    //更新json配置
    const conf = JSON.parse(fs.readFileSync(win64ConfigPath));
    console.log(conf);
    conf.version = latestVersion;
    conf.download = assetInfo.data.browser_download_url;
    conf.downloadCN = "https://ghproxy.com/"+assetInfo.data.browser_download_url
    // .replace(
    //     'https://github.com/',
    //     'https://download.fastgit.org/'
    // );
    fs.writeFileSync(win64ConfigPath, JSON.stringify(conf, '', 4));

    //删除缓存文件
    fs.unlinkSync(exePath);
    fs.unlinkSync(asarZip);
    
    //手动（其实是自动）更新CDN
    console.log(await github.request("GET https://purge.jsdelivr.net/gh/taozhiyu/TyProAction@main/config/releases/windows_64.json"))
    
};
