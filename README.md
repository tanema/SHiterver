SHiterver
=========
A flexible, simple, and bare metal web server written in bash

# Requirements.
- Bash 4.0. On OSX that means you will need to install it with homebrew
- sqlite3
- netcat

# Getting started
Just run `cd example && ../server.sh app.sh` that is all! So easy!

# Features
- Serves html templates using bash's own templating!
- Easily extendable!
- Easily exploitable!
- If you operating system can do it, so can this webserver!
- DB Ready!

# Caveats
- Not *exactly* secure
- Only support `GET` requests
- Doesn't *quite* accept multiple requests at a time

# Project Layout
- `server.sh` : Application entrypoint, listens and serves requests.
- `app.sh` : request handler definitions. Put all of your app logic here.
- `config.sh` : A good spot to put all of your confidential config.
- `db.sh` : defines the interface to the sqlite database.
- `views` : directory where your dynamic html templates are!


# Seriously
This is a joke, don't develop your application with bash.
