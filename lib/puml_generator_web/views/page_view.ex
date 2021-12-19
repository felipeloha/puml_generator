defmodule PumlGeneratorWeb.PageView do
  use PumlGeneratorWeb, :view

  def render("index.json", params) do
    %{
      somedata: params["data"] || "no data",
      moredata: "moredata"
    }
  end
end
