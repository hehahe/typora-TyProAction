async function downloadTool(core,url) {
    const tc = require('@actions/tool-cache');
    core.info(`Downloading <tool> from ${url}`)
    let token = core.getInput('token');

    const toolDownload = await tc.downloadTool(url);
    return toolDownload;
}

async function makeAvailableInPath(core, download, version, name) {
    const tc = require('@actions/tool-cache');
    const path = require("path");
    core.info(`Cache file ${download}`);
    const cachedPath = await tc.cacheFile(download, name, name, version);
    const filePath = path.join(cachedPath, name)

    core.info(`Make ${cachedPath} available in path`);
    core.addPath(cachedPath);
}

async function cacheFiles(core,name,version,url) {
    const tc = require('@actions/tool-cache');
    try {
        core.info(`>>> Version to set up: ${version}`);

        let path = tc.find(name, version);
        if (!path) {
            let download = await downloadTool(core,url)
            await makeAvailableInPath(core, download, version, name);
            core.info(`>>> <${name}> version ${version} installed successfully`);
        } else {
            core.info(`>> <${name}> version ${version} already installed`)
        }
    }
    catch (error) {
        core.setFailed(error.message);
    }
}

module.exports = async ({github, context, core,_t}) => {
//   if(/^update[\d\.]+$/.test(context.payload.issue.title)){
//     if(context.payload.issue.author_association!=='OWNER'){
//       console.log('权限检测未通过，已驳回')
//       await github.rest.issues.createComment({
//         issue_number: context.issue.number,
//         owner: context.repo.owner,
//         repo: context.repo.repo,
//         body: 'sorry, only the **OWNER** can use this keyword.\n'+
//               'but if it do have an update in TyPro,\n'+
//               'you can notice me if you have my contact details,\n'+
//               'otherwise maybe you can **ONLY** waiting until I remembered to updated it\n'+
//               '(maybe you can build your own repositories by clone?).\n\n'+
//               '抱歉，只有**所有者**(@taozhiyu)可以使用此关键字。\n'+
//               '但是，如果 TyPro 确实有更新，如果你有我的联系方式，你可以通知我；\n'+
//               '否则你可能**只能**等到我记得更新它\n'+
//               '（也许你可以通过克隆构建自己的存储库？）。'
//       });
//       await github.rest.issues.update({
//         owner: context.repo.owner,
//         repo: context.repo.repo,
//         issue_number: context.issue.number,
//         state: 'closed'
//       });
//       return
//     }
//     console.log('权限检测确认')
//     const urlList=context.payload.issue.body.match(/https?:\/\/[^)]+/g);
//     const fileVersion=context.payload.issue.title.substr(6)
//     console.log(urlList)
//     await cacheFiles(core,'asar.asar',fileVersion,urlList[0])
// //     fs.writeFileSync('newFile'+_t,result.data)
//   }else 
  if(context.payload.issue.title==='keygen'){
    console.log(context.payload.issue.body)
    console.log(KEYGEN_JS_CODE)
  }else{
      await github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: '[指令匹配错误]'
      });
      await github.rest.issues.update({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        state: 'closed'
      });
      return
  }
  
}
