defmodule PumlGenerator.PumlLogger do
  require Logger

  @behaviour Plug

  def init(opts), do: opts

  @excluded_paths ["/health", "/proxy"]
  def call(conn, _opts) do
    if Enum.member?(@excluded_paths, conn.request_path) ||
         !PumlGenerator.Generator.generation_enabled?() do
      conn
    else
      Plug.Conn.register_before_send(conn, fn conn ->
        Logger.debug("[request-body] #{Jason.encode!(conn.body_params)}")
        Logger.debug("[response-body] #{conn.resp_body}")
        conn
      end)
    end
  end
end
