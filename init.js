module.exports = async ({github, context, core}) => {
  console.log(context)
  if(context.payload.issue.title==='update'){
    console.log('权限检测')
    if(context.payload.issue.author_association!=='OWNER'){
      await github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: 'sorry, only the **OWNER** can use this keyword.\n'+
              'but if it do have an update in TyPro,\n'+
              'you can notice me if you have my contact details,\n'+
              'otherwise maybe you can **ONLY** waiting until I remembered to updated it\n'+
              '(maybe you can build your own repositories by clone?).\n\n'+
              '抱歉，只有**所有者**(@taozhiyu)可以使用此关键字。\n'+
              '但是，如果 TyPro 确实有更新，如果你有我的联系方式，你可以通知我；\n'+
              '否则你可能**只能**等到我记得更新它\n'+
              '（也许你可以通过克隆构建自己的存储库？）。'
      });
      await github.rest.issues.update({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
        state: 'closed'
      });
      return
    }
    console.log('权限检测完成')
  }else if(context.payload.issue.title==='keygen'){
    
  }
  console.log(context.payload.issue.body)
  
}
