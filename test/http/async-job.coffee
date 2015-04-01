jobs = require '../../src/http/jobs'

###
Express request handler combinator that makes the endpoint appear as an async job to the consumer
###
module.exports = (next) -> (req, res) ->
  unless req.get(jobs.ASYNC_JOB_FEATURE_HEADER) is 'true'
    res.status(501).send({error: 'async job feature header not received'}).end()
  else if req.get(jobs.JOB_ID_HEADER) isnt '123'
    # Backend acknowledges it has accepted job
    job = {}
    job[jobs.JOB_ROOT_KEY] = id: 123
    res.status(jobs.JOB_HTTP_STATUS).send(job).end()
  else
    # Backend responds with actual content once job is complete
    next(req, res)
