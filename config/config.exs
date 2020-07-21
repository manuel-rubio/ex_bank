import Config

config :logger,
  backends: [:console, {LoggerFileBackend, :debug_log}],
  handle_otp_reports: true,
  handle_sasl_reports: true

config :logger, :debug_log,
  path: "logs/debug.log",
  level: :debug

import_config "#{Mix.env()}.exs"
