defmodule PumlGenerator.Handler do
  alias PumlGenerator.PayloadHandler
  alias PumlGenerator.Writer
  require Logger

  def append(log), do: append(log, nil)

  def append(log, metadata) do
    # IO.inspect(log)
    handle_log(log, metadata)
  rescue
    e ->
      IO.puts("error appending log #{inspect(e)}")
      IO.puts("log: #{inspect(log)}")
      IO.puts("metadata: #{inspect(metadata)}")
      IO.puts(inspect(Exception.blame(:error, e, __STACKTRACE__)))
  end

  defp handle_log(log), do: handle_log(log, nil)

  defp handle_log(%{method: _method, url: _url} = call, _) do
    :hackney
    |> PayloadHandler.insert_item(call)
    |> PayloadHandler.enqueue_request()
  end

  defp handle_log(%{response_payload: response_payload, status: status}, _) do
    :hackney
    |> PayloadHandler.update_item(%{response_payload: response_payload, status: status})
    |> PayloadHandler.enqueue_response()
  end

  #### collect controller request and log puml
  defp handle_log([method, _, url | _], _) when method in ["POST", "GET", "PATCH", "PUT"] do
    PayloadHandler.insert_item(:controller, %{method: method, url: url})
  end

  defp handle_log("[request-body] " <> request_payload, _) do
    :controller
    |> PayloadHandler.update_item(%{request_payload: request_payload})
    |> PayloadHandler.enqueue_request()
  end

  #### END collect controller request and log puml

  #### collect controller response and log puml
  defp handle_log("[response-body] " <> response_payload, _) do
    PayloadHandler.update_item(:controller, %{response_payload: response_payload})
  end

  defp handle_log(["Sent", _, status | _], _) do
    :controller
    |> PayloadHandler.update_item(%{status: status})
    |> PayloadHandler.enqueue_response()
  end

  #### END collect controller response and log puml

  defp handle_log("[WEBHOOK] " <> url, metadata) do
    handle_message(
      "POST",
      url,
      metadata[:puml_event],
      "200"
    )
  end

  defp handle_log("[SQS]", metadata) do
    handle_message(
      "SQS",
      metadata[:puml_event_type],
      metadata[:puml_event],
      metadata[:puml_status]
    )
  end

  defp handle_log("[opt-start]", metadata) do
    PayloadHandler.enqueue_ordered_item(%{optional: "start", label: metadata[:puml_label]})
  end

  defp handle_log("[opt-end]", _) do
    PayloadHandler.enqueue_ordered_item(%{optional: "end"})
  end

  defp handle_log("[puml-end]", _) do
    Writer.write()
  end

  defp handle_log("[puml-info]" <> _ = log, _) do
    IO.puts("#{log}")
  end

  # handle hackney log
  defp handle_log(msg, :hackney) do
    {_, _, _, {_, _, args}, _} = msg
    [_, op, _, params | _] = args
    op = to_string(op)

    if op in ["request"] do
      method = params[:method]

      url =
        get_first_matching_string(params[:url], "/") ||
          get_first_matching_string(params[:url], "")

      handle_log(%{method: method, url: url, request_payload: params[:body] || ""})
    end

    if op in ["got response"] do
      response = params[:response]
      status = elem(response, 1)
      handle_log(%{response_payload: "", status: status})
    end
  end

  defp handle_log(_, _) do
    # IO.puts "[no-puml-parser-found] #{log}"
  end

  defp get_first_matching_string(param, substring) do
    param
    |> Tuple.to_list()
    |> Enum.find(&(is_binary(&1) && &1 != "" && String.starts_with?(&1, substring)))
  end

  defp handle_message(method, url, request_payload, status) do
    call = %{
      method: method,
      url: url,
      request_payload: request_payload,
      status: status
    }

    PayloadHandler.enqueue_request(call)
    PayloadHandler.enqueue_response(call)
  end
end
