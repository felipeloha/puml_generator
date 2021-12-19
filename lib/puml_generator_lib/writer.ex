defmodule PumlGenerator.Writer do
  alias PumlGenerator.PayloadHandler

  @internal_group_start %{internal: "start"}
  @internal_group_end %{internal: "end"}

  defp config(key) do
    PayloadHandler.config(key)
  end

  def init_puml do
    File.rm(config(:path))

    puml = """
    @startuml
    """

    save([puml])
  end

  def write_participants do
    actor = config(:actor)
    public = config(:public)
    self = config(:self)
    participants = config(:participants)

    puml_participants_def =
      map_participants(
        participants,
        fn {id, descr} -> "participant #{descr} as #{id}" end
      )

    puml_participants =
      map_participants(
        participants,
        fn {id, descr} -> "participant #{descr} as #{id}" end
      )

    puml_participants_def_public =
      map_participants(
        participants,
        fn {id, _} -> "participant #{public} as #{id}" end
      )

    puml = """
    ' Definitions of participants
    actor #{actor}
    !if $WITH_INTERNALS()
    #{puml_participants_def}

    box "#{public}" #EEEEEE
      #{puml_participants}
    end box

    !else

    #{"" || puml_participants_def_public}
    participant #{public} as #{self}

    !endif
    """

    save([puml])
  end

  def write do
    PayloadHandler.get_queue()
    |> Enum.sort_by(& &1.order)
    |> Enum.map(&map_defaults(&1))
    |> add_internals()
    # |> IO.inspect(limit: :infinity)
    |> Enum.each(&write_puml(&1))

    end_puml()
  end

  defp end_puml do
    puml = """
    @enduml
    """

    save([puml])
  end

  defp map_defaults(opts) do
    opts
    |> merge_default_args
    |> map_participants
  end

  defp add_internals(items) do
    items
    |> Enum.reduce(
      {false, []},
      fn item, {open, acc} ->
        {open, internal} = get_internal(open, item)
        item = Map.put(item, :internal_message, open)
        {open, acc ++ internal ++ [item]}
      end
    )
    |> elem(1)
  end

  defp get_internal(is_internal_open?, item) do
    is_internal_call? = Map.get(item, :is_internal?)
    do_get_internal(is_internal_open?, is_internal_call?)
  end

  defp do_get_internal(is_internal_open?, nil), do: {is_internal_open?, []}
  defp do_get_internal(false, true), do: {true, [@internal_group_start]}
  defp do_get_internal(true, false), do: {false, [@internal_group_end]}
  defp do_get_internal(is_internal_open?, _), do: {is_internal_open?, []}

  defp write_puml(%{internal: "start"}) do
    puml = """

    $INTERNAL_GROUP("internal calls")
    """

    save([puml])
  end

  defp write_puml(%{internal: "end"}) do
    puml = """

    $INTERNAL_GROUP_END()
    """

    save([puml])
  end

  defp write_puml(%{optional: "start", label: label}) do
    label = label || ""

    puml = """

    $OPT(#{label})
    """

    save([puml])
  end

  defp write_puml(%{optional: "end"}) do
    puml = """

    $OPT_END()
    """

    save([puml])
  end

  defp write_puml(%{
         type: :request,
         from: from,
         to: to,
         url: url,
         method: method,
         request_payload: request_payload,
         internal_message: internal_message
       }) do
    payload =
      PayloadHandler.map_payload(
        request_payload,
        config(:allowed_request_params),
        config(:value_params)
      )

    puml = """

    $#{prefix(internal_message)}MESSAGE(#{from}, #{to}, \"#993333\", \"#{method}\", \"#{PayloadHandler.mask_url(url)}\", #{payload})
    """

    save([puml])
  end

  defp write_puml(%{
         type: :response,
         response_payload: response_payload,
         status: status,
         internal_message: internal_message
       }) do
    payload =
      PayloadHandler.map_payload(
        response_payload,
        config(:allowed_response_params),
        config(:value_params)
      )

    puml = """
    $#{prefix(internal_message)}RESPONSE(\"#{status}\",#{payload})
    """

    save([puml])
  end

  defp prefix(true), do: "INTERNAL_"
  defp prefix(false), do: ""

  # TODO the string could be collected and the file written at the very end
  defp save(data) do
    {:ok, file} = File.open(config(:path), [:append, {:delayed_write, 100, 20}])
    Enum.each(data, &IO.binwrite(file, &1))
    File.close(file)
  end

  defp merge_default_args(item) do
    Map.merge(
      %{
        request_payload: "",
        response_payload: "",
        status: "200"
      },
      item
    )
  end

  defp map_participants(%{url: url} = item) do
    {from, to, is_internal?} = get_participants(url) || {config(:actor), config(:self), false}

    item
    |> Map.put(:from, from)
    |> Map.put(:to, to)
    |> Map.put(:url, url)
    |> Map.put(:is_internal?, is_internal?)
  end

  defp map_participants(item), do: item

  defp get_participants(url) do
    Enum.find_value(config(:url_participant_map), &get_participants(&1, url))
  end

  defp get_participants(%{urls: patterns} = map, url) do
    Enum.find_value(patterns, &get_participants(&1, url, map))
  end

  defp get_participants(pattern, url, %{from: from, to: to, internal: is_internal?}) do
    if String.contains?(url, pattern) do
      {map(from), map(to), is_internal?}
    end
  end

  defp map(:self), do: config(:self)
  defp map(:actor), do: config(:actor)
  defp map(side), do: side

  defp map_participants(participants, map) do
    participants
    |> Enum.map_join("\n", &map.(&1))
  end
end
