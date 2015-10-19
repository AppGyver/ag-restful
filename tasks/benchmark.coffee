Bacon = require 'baconjs'
Promise = require 'bluebird'
http = require('../src/http')(Promise, Bacon)

stats = require 'simple-statistics'

###
(f: () -> Promise) -> milliseconds
###
time = (f) ->
  timestamp = +new Date
  Promise.resolve(f()).then ->
    (+new Date)-timestamp

markCompletion = (p) ->
  p.then(
    (v) ->
      process.stdout.write '.'
      v
    (e) ->
      process.stdout.write 'x'
      throw e
  )

benchmarkResultStream = (f, concurrency, total) ->
  Bacon.fromArray(i for i in [0..total-1])
    .flatMapWithConcurrencyLimit(concurrency, (i) ->
      Bacon.fromPromise markCompletion time(f)
    )

module.exports = (grunt) ->

  benchmark = (f, concurrency, total) -> ->
    grunt.log.ok "Running benchmark..."
    new Promise (resolve) ->
      benchmarkResultStream(f, concurrency, total)
        .fold([], (list, time) ->
          list.push time
          list
        )
        .onValue (times) ->
          console.log ""
          grunt.log.ok    "Requests completed:       #{times.length}"
          grunt.log.error "Requests failed:          #{total - times.length}"
          grunt.log.ok    "Execution times (milliseconds)"
          console.log """
          Minimum:       #{~~stats.min(times)}
          10% quantile:  #{~~stats.quantile(times, 0.1)}
          Mean:          #{~~stats.mean(times)}
          90% quantile:  #{~~stats.quantile(times, 0.9)}
          Maximum:       #{~~stats.max(times)}
          """
          resolve(times)

  getBenchmarkConfig = ->
    for varName in ['BENCHMARK_URL', 'BENCHMARK_STEROIDS_API_KEY', 'BENCHMARK_STEROIDS_APP_ID']
      throw new Error ".env needs #{varName}" unless process.env[varName]?

    BENCHMARK_URL: process.env.BENCHMARK_URL
    BENCHMARK_STEROIDS_API_KEY: process.env.BENCHMARK_STEROIDS_API_KEY
    BENCHMARK_STEROIDS_APP_ID: process.env.BENCHMARK_STEROIDS_APP_ID
    BENCHMARK_CONCURRENCY: process.env.BENCHMARK_CONCURRENCY ? 10
    BENCHMARK_REQUESTS: process.env.BENCHMARK_REQUESTS ? 100

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
    Concurrent requests:      #{config.BENCHMARK_CONCURRENCY}
    Requests to complete:     #{config.BENCHMARK_REQUESTS}
    """

    time(benchmark(runRequest, config.BENCHMARK_CONCURRENCY, config.BENCHMARK_REQUESTS)).then (totalTime) ->
      grunt.log.ok """
      Total time to completion: #{totalTime}
      """
      done()
