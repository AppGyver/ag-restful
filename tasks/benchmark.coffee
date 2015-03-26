Promise = require 'bluebird'
http = require('../src/http')(Promise)

###
(f: () -> Promise) -> milliseconds
###
time = (f) ->
  timestamp = +new Date
  Promise.resolve(f()).then ->
    (+new Date)-timestamp

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
    runRequest = requestRunner getBenchmarkConfig()
    time(runRequest).then (v) ->
      console.log v
      done()
