defmodule PumlGeneratorWeb.PageView do
  use PumlGeneratorWeb, :view

  def render("index.json", _) do
    %{
      somedata: "somedata",
      moredata: "moredata"
    }
  end
end
