import Config

# Global config
config :ex_cldr,
  default_locale: "en-001",
  default_backend: MyApp.Cldr

config :ex_unit,
  module_load_timeout: 220_000,
  case_load_timeout: 220_000,
  timeout: 120_000
