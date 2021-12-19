defmodule PumlGeneratorWeb.PageControllerTest do
  use PumlGeneratorWeb.ConnCase
  use PumlGenerator.Generator

  test "GET /", %{conn: conn} do
    record_puml(path: "process.puml")
    conn = get(conn, "/amazing_service", data: "first call")
    assert json_response(conn, 200)["somedata"] =~ "first call"

    conn = get(conn, "/amazing_service", data: "second call")
    assert json_response(conn, 200)["somedata"] =~ "second call"
    save_puml()
  end
end
