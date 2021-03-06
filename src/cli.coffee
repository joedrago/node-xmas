# Example lines from inputList file:
#
# Name namesemail@example.com CantGiveThisPersonAPresent
# CantGiveThisPersonAPresent herp@example.com

fs = require 'fs'
nodemailer = require 'nodemailer'

syntax = ->
  console.log "Syntax: xmas [-h]"
  console.log "        xmas inputList username password"
  process.exit(1)

main = ->
  args = require('minimist')(process.argv.slice(2), {
    boolean: ['h', 'v', 'c', 'u', 'x']
    string: ['t','m','s']
    alias:
      help: 'h'
  })
  if args.help or args._.length < 3
    syntax()

  inputList = args._[0]
  emailUsername = args._[1]
  emailPassword = args._[2]

  console.log "inputList    : #{inputList}"
  console.log "emailUsername: #{emailUsername}"
  console.log "emailPassword: #{emailPassword}"

  lines = String(fs.readFileSync(inputList)).split(/[\r\n]/)
  people = []
  for line in lines
    pieces = line.split /\s+/
    if pieces.length >= 2
      blacklist = {}
      for name in pieces.slice(2)
        blacklist[name] = true
      person =
        name: pieces[0]
        email: pieces[1]
        blacklist: blacklist
        dst: null
        santa: false
      people.push person

  console.log people

  # here comes a super inefficient algorithm, because I'm lazy. Buckle up!
  console.log "If this sits here more than 5 seconds without printing the present list, break and try again. This is so lame."
  presents = {}
  for person in people
    loop
      index = Math.floor(Math.random() * people.length)
      dst = people[index]
      if (dst.name != person.name) and not dst.santa and not person.blacklist[dst.name]
        person.dst = dst
        dst.santa = person
        break

  for person in people
    console.log "#{person.santa.name} buys a present for #{person.name}"

  transporter = nodemailer.createTransport {
    service: 'Gmail'
    auth:
      user: emailUsername
      pass: emailPassword
  }

  for person in people
    console.log "#{person.santa.name} buys a present for #{person.name}"

    body = """
      Hello, #{person.santa.name}!<br>
      <br>
      Please get a present for <b>#{person.name}</b>. <i>Merry Christmas!</i><br>
      <br>
      -- The Christmas Thing<br>
      <br>
      PS. <b><i>Do not reply to this email!</i></b> It was autogenerated by a script, and the sender does not know who you are getting a present for.
    """

    mailOptions =
      from: "The Christmas Thing <#{emailUsername}>"
      to: person.santa.email
      subject: 'The Christmas Thing!'
      html: body

    # console.log mailOptions

    console.log "Sending mail to #{person.santa.email}"
    transporter.sendMail mailOptions, (error, info) ->
      if error
        return console.log(error)
      console.log 'Message sent: ' + info.response

module.exports =
  main: main
