defmodule Shortener.Repo do
  use Ecto.Repo,
    otp_app: :shortener,
    adapter: Ecto.Adapters.Postgres
end
