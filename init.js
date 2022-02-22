import * as core from "actions/github-script";
async function run(){
  try {
    core.info(`Hello world`);
    const eventName = github.context.eventName;
    core.info(`name is ${eventName}`);
  } catch (error) {
    core.setFailed(error.message);
  }
}

module.exports = async ({github, context, core}) => {
  const {SHA} = process.env
  const commit = await github.rest.repos.getCommit({
    owner: context.repo.owner,
    repo: context.repo.repo,
    ref: `${SHA}`
  })
  core.exportVariable('author', commit.data.commit.author.email)
  run();
}
