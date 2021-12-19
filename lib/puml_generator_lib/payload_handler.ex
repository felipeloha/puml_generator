defmodule PumlGenerator.PayloadHandler do
  alias PumlGenerator.Cache

  def get_queue do
    Cache.get(:queue)
  end

  def update_item(key, item), do: Cache.update_item(key, item)

  def enqueue_request(%{order: _order} = item) do
    item
    |> Map.put(:type, :request)
    |> enqueue_item()
  end

  def enqueue_request(item), do: enqueue_ordered_item(item)

  def enqueue_ordered_item(item) do
    item
    |> put_order()
    |> enqueue_request()
  end

  def enqueue_response(item) do
    item
    |> put_order()
    |> Map.put(:type, :response)
    |> enqueue_item()
  end

  defp enqueue_item(item) do
    items = Cache.get(:queue) || []
    Cache.insert(:queue, items ++ [item])
  end

  def insert_item(key, item) do
    item = put_order(item)
    Cache.insert(key, item)
    item
  end

  defp get_next_order do
    order = Cache.get(:order) || 0
    Cache.insert(:order, order + 1)
    order
  end

  defp put_order(item) do
    order = get_next_order()
    Map.put(item, :order, order)
  end

  def config(key) do
    Cache.get(:config)[key]
  end

  defp allowed_parts do
    config(:allowed_url_parts)
  end

  # masks ids with singularizing the previous url part
  def mask_url(url) do
    parts = Enum.with_index(String.split(url, "/"))

    parts
    |> Enum.map_join("/",fn {part, index} ->
      if part in allowed_parts() or part == "" do
        part
      else
        parts
        |> Enum.at(index - 1)
        |> elem(0)
        |> String.graphemes()
        |> mask_parameter()
      end
    end)
  end

  def map_payload(payload_str, allowed_params, value_params) do
    payload_str
    |> decode_payload
    |> Enum.filter(fn {k, _} -> k in allowed_params end)
    # TODO handle nested attributes
    |> Enum.map(&map_payload_entry(&1, value_params))
    |> case do
      [] -> "\"\""
      params -> params_to_string(params)
    end
  end

  defp map_payload_entry({k, v}, value_params) do
    if k in value_params do
      "#{k}: **#{v}**"
    else
      "#{k}: **#{k}**"
    end
  end

  # builds a json payload with ident
  defp params_to_string(params) do
    start_payload = "\"\\n{\\n  "
    end_payload = "\\n}\""
    start_payload <> "#{Enum.join(params, "\\n   ")}" <> end_payload
  end

  defp decode_payload(payload_str) do
    case Jason.decode(payload_str) do
      {:ok, %{"request" => payload}} -> payload
      {:ok, %{"payload" => payload}} -> payload
      {:ok, payload} -> payload
      _ -> %{}
    end
  rescue
    e ->
      IO.puts("Error Jason.decoding '#{payload_str}': #{e}")
      reraise e, __STACKTRACE__
  end

  # TODO use a library to singularize
  defp mask_parameter(chars), do: do_mark_param(chars, List.last(chars))
  defp do_mark_param(chars, "s"), do: do_mark_param(Enum.drop(chars, -1), "")
  defp do_mark_param(chars, _), do: "{#{Enum.join(chars)}_id}"
end
