jobs = require '../../src/http/jobs'

###
Express request handler combinator that makes the endpoint appear as an async job to the consumer
###
module.exports = (next) -> (req, res) ->
  if req.get(jobs.JOB_ID_HEADER) isnt '123'
    # Backend acknowledges it has accepted job
    res.set(jobs.JOB_ID_HEADER, '123')
    res.status(jobs.JOB_HTTP_STATUS)
    res.end()
  else
    # Backend responds with actual content once job is complete
    next(req, res)
