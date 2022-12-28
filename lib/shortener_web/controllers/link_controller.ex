defmodule ShortenerWeb.LinkController do
  use ShortenerWeb, :controller

  alias Shortener.Links
  alias Shortener.Links.Link
  alias Phoenix.PubSub


  def index(conn, _params) do
    links = Links.list_links()
    render(conn, "index.html", links: links)
  end

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"link" => link_params}) do
    case create_link(link_params) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link created successfully.")
        |> redirect(to: Routes.link_path(conn, :show, link))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    try do
      link = Links.get_link!(id)
      domain = System.get_env("APP_BASE_URL") || nil
      render(conn, "show.html", link: link, domain: domain)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Invalid link")
        |> redirect(to: Routes.link_path(conn, :new))
    end
  end

  def edit(conn, %{"id" => id}) do
    link = Links.get_link!(id)
    changeset = Links.change_link(link)
    render(conn, "edit.html", link: link, changeset: changeset)
  end

  def update(conn, %{"id" => id, "link" => link_params}) do
    link = Links.get_link!(id)

    case Links.update_link(link, link_params) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link updated successfully.")
        |> redirect(to: Routes.link_path(conn, :show, link))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", link: link, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    link = Links.get_link!(id)
    {:ok, _link} = Links.delete_link(link)

    conn
    |> put_flash(:info, "Link deleted successfully.")
    |> redirect(to: Routes.link_path(conn, :index))
  end

  def redirect_to(conn, %{"id" => id}) do
    try do
      link = Links.get_link!(id)
      throw_events_on_redirect(link)

      redirect(conn, external: link.url)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Invalid link")
        |> redirect(to: Routes.link_path(conn, :new))
    end
  end

  defp throw_events_on_redirect(link) do
    Task.start(fn -> update_visits_for_link(link) end)
    Task.start(fn -> PubSub.broadcast(Shortener.PubSub, "stats#{link.id}", {:stats, link.visits + 1}) end)
  end

  defp update_visits_for_link(link) do
    Links.update_link(link, %{visits: link.visits + 1})
  end

  defp create_link(link_params) do
    key = random_string(8)
    params = Map.put(link_params, "id", key)

    try do
      case Links.create_link(params) do
        {:ok, link} ->
          {:ok, link}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, changeset}
      end
    rescue
      Ecto.ConstraintError ->
        create_link(params)
    end
  end

  defp random_string(string_length) do
    :crypto.strong_rand_bytes(string_length)
    |> Base.url_encode64()
    |> binary_part(0, string_length)
  end
end
