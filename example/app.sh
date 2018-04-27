# ==============
# Setup Database
# ==============
query "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);"
query "INSERT INTO users (name) VALUES ('tim')"

# ==============
# Setup routes
# ==============
ROUTES['^hello']="greeting_handler"
ROUTES['^date']="date_handler"
ROUTES['^users']="users_handler"
ROUTES['^$']="root_handler"

# ==============
# Route handlers
# ==============
greeting_handler() {
  render "$HTTP_200" "Hello ${QUERY["name"]}"
}

date_handler() {
  render "$HTTP_200" "$(date)"
}

users_handler() {
  USERS=$(query "select * from users")
  render "$HTTP_200" "users.html"
}

root_handler() {
  render "$HTTP_200" "index.html"
}
