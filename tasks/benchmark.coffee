Promise = require 'bluebird'
http = require('../src/http')(Promise)

stats = require 'simple-statistics'

###
(f: () -> Promise) -> milliseconds
###
time = (f) ->
  timestamp = +new Date
  Promise.resolve(f()).then ->
    (+new Date)-timestamp

concurrently = (concurrency = 1) -> (f) ->
  Promise.all(
    for i in [0..concurrency]
      f()
  )

benchmark = (f, concurrency, total) -> ->
  concurrently(concurrency)(->
    time(f)
  ).then (times) ->
    console.log """
    Execution times (milliseconds)
    ==============================
    Minimum:    #{~~stats.min(times)}
    Mean:       #{~~stats.mean(times)}
    Maximum:    #{~~stats.max(times)}
    """

module.exports = (grunt) ->
  getBenchmarkConfig = ->
    BENCHMARK_URL: process.env.BENCHMARK_URL
    BENCHMARK_STEROIDS_API_KEY: process.env.BENCHMARK_STEROIDS_API_KEY
    BENCHMARK_STEROIDS_APP_ID: process.env.BENCHMARK_STEROIDS_APP_ID
    CONCURRENCY: process.env.CONCURRENCY ? 10
    REQUESTS: process.env.REQUESTS ? 100

  requestRunner = (config) -> ->
    http.request('get', config.BENCHMARK_URL, {
      headers:
        steroidsApiKey: config.BENCHMARK_STEROIDS_API_KEY
        steroidsAppId: config.BENCHMARK_STEROIDS_APP_ID
    })

  grunt.registerTask 'benchmark:http', ->
    done = @async()
    config = getBenchmarkConfig()
    runRequest = requestRunner config
    grunt.log.ok """
    Benchmarking endpoint:    #{config.BENCHMARK_URL}
    Concurrent requests:      #{config.CONCURRENCY}
    Requests to complete:     #{config.REQUESTS}
    """

    time(benchmark(runRequest, config.CONCURRENCY, config.REQUESTS)).then (totalTime) ->
      grunt.log.ok """
      Total time to completion: #{totalTime}
      """
      done()
