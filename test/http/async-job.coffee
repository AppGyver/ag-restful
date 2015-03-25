###
Express request handler combinator that makes the endpoint appear as an async job to the consumer
###
module.exports = (next) -> (req, res) ->
  if req.get('x-proxy-request-id') isnt 123
    # Backend acknowledges it has accepted job
    res.set('x-proxy-request-id', 123)
    res.status(202)
    res.end()
  else
    # Backend responds with actual content once job is complete
    next(req, res)
