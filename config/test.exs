import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :puml_generator, PumlGeneratorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "LvZigPORUBoNNUCTxY7wewadcQREJgDhzuZxTBPJGuMUbB3Ty/7wfVFGUJnhRoZR",
  server: false

# In test we don't send emails.
config :puml_generator, PumlGenerator.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :puml_generator, PumlGenerator.Generator,
  allowed_url_parts: ~w(amazing_service google.com yahoo.com status customer.com webhook_endpoint),
  allowed_request_params: ~w(somedata moredata data),
  allowed_response_params: ~w(somedata data),
  value_params: ["data"],
  self: "amazing_service",
  actor: "customer",
  public: "serious_service_name",
  participants: [
    {"amazing_service", "AmazingService"},
    {"tp", "ThirdParty"}
  ],
  url_participant_map: [
    {"/status", :self, "tp", true},
    {"yahoo", :self, "tp", true},
    {"amazing_service", :actor, :self},
    {"/webhook_endpoint", :self, :actor}
  ]
