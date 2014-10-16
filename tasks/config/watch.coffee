module.exports =
  test:
    files: [
      '<%= files.src %>'
      '<%= files.test %>'
    ]
    tasks: [
      'coffeelint'
      'test'
    ]

  compile:
    files: [
      '<%= files.src %>'
    ]
    tasks: [
      'coffeelint'
      'compile'
    ]
