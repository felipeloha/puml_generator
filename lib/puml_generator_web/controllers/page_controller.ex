defmodule PumlGeneratorWeb.PageController do
  use PumlGeneratorWeb, :controller

  def index(conn, _params) do
    render(conn, "index.json")
  end
end
