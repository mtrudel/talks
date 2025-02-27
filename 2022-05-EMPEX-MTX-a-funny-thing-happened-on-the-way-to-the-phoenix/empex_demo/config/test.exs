import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :empex_demo, EmpexDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Q6cHNGwKYlzpzFhBAPZDu/6wLt5Fj4jlAi5+7y7DDbGBGipKWGypVOb0LX+ZbYRS",
  server: false

# In test we don't send emails.
config :empex_demo, EmpexDemo.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
