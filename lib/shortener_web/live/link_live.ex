defmodule ShortenerWeb.LinkLive do
  use ShortenerWeb, :live_view

  alias Shortener.Links
  alias Shortener.Links.Link
  alias Phoenix.PubSub

  @topic "stats"

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(Shortener.PubSub, "stats#{id}")

    link = Links.get_link!(id)
    domain = System.get_env("APP_BASE_URL") || nil

    {:ok, assign(socket,
      id: id,
      link: link,
      domain: domain,
      realtime_visits: link.visits,
    )}

  end

  def handle_info({:stats, payload}, socket) do
    {:noreply, assign(socket, :realtime_visits, payload)}
  end

end
