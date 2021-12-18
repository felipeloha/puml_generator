defmodule PumlGeneratorWeb.PageControllerTest do
  use PumlGeneratorWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert json_response(conn, 200)["somedata"] =~ "somedata"
  end
end
