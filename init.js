module.exports = async ({github, context, core}) => {
//   const {SHA} = process.env
//   const commit = await github.rest.repos.getCommit({
//     owner: context.repo.owner,
//     repo: context.repo.repo,
//     ref: `${SHA}`
//   })
  core.exportVariable('github', github)
  core.exportVariable('context', context)
  core.exportVariable('core', core)
//   core.exportVariable('author', commit.data.commit.author.email)
}
