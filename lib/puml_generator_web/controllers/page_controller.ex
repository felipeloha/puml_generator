defmodule PumlGeneratorWeb.PageController do
  use PumlGeneratorWeb, :controller

  def index(conn, params) do
    HTTPoison.get("https://google.com/status")
    HTTPoison.get("https://yahoo.com")
    HTTPoison.post("https://customer.com/webhook_endpoint", Poison.encode!(%{data: "webhook"}))
    render(conn, "index.json", params)
  end
end
