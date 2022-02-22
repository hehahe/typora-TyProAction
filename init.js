module.exports = async ({github, context, core}) => {
//   const {SHA} = process.env
//   const commit = await github.rest.repos.getCommit({
//     owner: context.repo.owner,
//     repo: context.repo.repo,
//     ref: `${SHA}`
//   })
  core.info('github',JSON.stringify(github,'',4))
  core.exportVariable('context',JSON.stringify(context,'',4) )
//   core.exportVariable('author', commit.data.commit.author.email)
}
