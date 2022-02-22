module.exports = async ({github, context, core}) => {
  
  console.log(context)
  console.log(context.payload.issue.body)
}
