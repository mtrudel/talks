import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :demo2, Demo2Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "W/I33TFqb7m66IUT8SvEjN2jDSecPiHWEhzxf2gw7AcdGs0n8/pNKkb9LIgNQnOd",
  server: false

# In test we don't send emails.
config :demo2, Demo2.Mailer,
  adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
