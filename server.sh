#!/usr/local/bin/bash
#
# A fast and simple web server.
#
# See LICENSE for licensing information.
#
# author: Tim Anema, 2018

# Config Variables
APPLICATION=$1
PORT=${2:-8080}
DBNAME=${3:-"local.db"}

# Constants
HTTP_200="200 OK"
HTTP_404="404 Not Found"
declare -A ROUTES

# query will directly query your sqlite database and return csv formatted data
# for easy iteration!
query() {
  sqlite3 -csv $DBNAME "$1"
}

render_partial() {
  local dir=${2:-views}
  eval "echo \"$(cat ./$dir/$1)\""
}

# render format and output the response to the request. You just need to pass in
# the response status and either a string to be rendered or a filename that exist
# in the views directory relative to your application.
render() {
  local status="$1"
  local body="$2"
  local contentType=${3:-$(_get_content_type $body)}

  RESPONSE_HEADERS["Content-Type"]="$contentType"
  if [ -f "./views/$body"  ]; then # if this file exists, render it
    body="$(render_partial $body)"
  elif [ -f "./public/$body"  ]; then # if this file exists, render it
    body="$(render_partial $body public)"
  fi

  local response="HTTP/1.1 $status\r\n"
  for header in "${!RESPONSE_HEADERS[@]}"; do
    response+="$header: ${RESPONSE_HEADERS[$header]}\r\n"
  done
  response+="\r\n$body"
  echo -en "$response" > out
}

# parse the first line of a request
_parse_request_uri() {
  # cut out the request path and split it on ? so we get path and query
  IFS='?'; parts=($REQUEST_URI); unset IFS;
  # extract the path without the / prefix
  REQUEST_PATH=${parts[0]#"/"}
  # set our location response header
  RESPONSE_HEADERS["Location"]="/$REQUEST_PATH"
  # split query by & so that we have a lot of key value pairs
  IFS='&'; query=(${parts[1]}); unset IFS;
  for f in "${query[@]}"; do
    # split by = to get the query name and value
    IFS='='; query_part=($f); unset IFS;
    QUERY["${query_part[0]}"]="${query_part[1]}"
  done
}

_get_content_type() {
  extension="${1##*.}"
  if [ $extension == "css" ]; then
    echo "text/css"
  elif [ $extension == "js" ]; then
    echo "application/javascript"
  elif [ $extension == "html" ]; then
    echo "text/html"
  else
    echo "text/plain"
  fi
}

# request has been parsed and now we need to match it to a handler
_handle_request() {
  # check routes for a regex that matches the request path
  for route in "${!ROUTES[@]}"; do
    if echo $REQUEST_PATH | grep -qE $route; then
      eval ${ROUTES[$route]}
      return
    fi
  done

  # serve public files
  if [ -f "./public/$REQUEST_PATH"  ]; then
    render "$HTTP_200", "$REQUEST_PATH"
    return
  fi

  # If no route was found we will render a 404
  render "$HTTP_404" "Resource '/$REQUEST_PATH' Not Found"
}

# "start" the application and let it declare routes.
source "$APPLICATION"

# Listen and serve requests using netcat and a tricky fifo
rm -f out
mkfifo out
trap "rm -f out" EXIT

echo "listening on :$PORT"
while true; do
  # redeclare request and response variables for every request.
  export REQUEST_PATH
  declare -A REQUEST_HEADERS
  declare -A QUERY
  declare -A RESPONSE_HEADERS

  # set default response headers
  RESPONSE_HEADERS["Connection"]="keep-alive"
  RESPONSE_HEADERS["Date"]="$(date +"%a, %d %b %Y %H:%M:%S %Z")"
  RESPONSE_HEADERS["Server"]="oh god no"

  # parse the netcat output, to build the answer redirected to the pipe "out".
  cat out | nc -l $PORT | (
    read line
    read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<<"$line"
    _parse_request_uri

    while read line && line=$(echo "$line" | tr -d '[\r\n]') && [ "x$line" != x ]; do
      IFS=': '; header=($line); unset IFS;
      REQUEST_HEADERS["${header[0]}"]="${header[1]}"
    done

    _handle_request
  )
done
