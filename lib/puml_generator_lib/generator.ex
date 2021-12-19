defmodule PumlGenerator.Generator do
  def generation_enabled? do
    # flag = System.get_env("GENERATE_PUML") || "false"
    flag = System.get_env("GENERATE_PUML") || "true"
    flag == "true"
  end

  defmacro __using__(opts) do
    quote bind_quoted: [my_opts: opts] do
      require Logger
      alias PumlGenerator.Handler
      alias PumlGenerator.PumlBackend
      alias PumlGenerator.Cache

      def puml_opt_start(label \\ nil) do
        Logger.debug("[opt-start]", puml_label: label)
      end

      def puml_opt_end do
        Logger.debug("[opt-end]")
      end

      def puml_webhook(url, entity) do
        Logger.debug("[WEBHOOK] #{url}", puml_event: Poison.encode!(entity))
      end

      def puml_sqs_msg(event_id, event_type, event) do
        Logger.debug("[SQS]", puml_event_type: event_type, puml_event: event, puml_status: "ACKN")
      end

      def record_puml, do: record_puml([])

      def record_puml(args) do
        if PumlGenerator.Generator.generation_enabled?() do
          do_init(args)
        end
      end

      defp do_init(args) do
        Cache.init_cache(:puml)
        config = opts(args)
        :ets.insert(:puml, {:previous_log_level, Logger.level()})
        :ets.insert(:puml, {:config, config})

        Logger.configure(level: :debug)
        res = Logger.add_backend({PumlBackend, :puml_backend})

        :hackney_trace.enable(
          :max,
          {
            fn msg, _ -> Handler.append(msg, :hackney) end,
            "data"
          }
        )

        Logger.info("[puml-info] puml generator initialized, recording...")
        PumlGenerator.Writer.init_puml()
        PumlGenerator.Writer.write_participants()
      end

      def save_puml do
        if PumlGenerator.Generator.generation_enabled?() do
          Logger.flush()
          Logger.info("[puml-info] generating puml in path " <> Cache.get(:config)[:path])

          Logger.debug("[puml-end]")
          level = Cache.get(:previous_log_level)
          Logger.configure(level: level)
          Logger.remove_backend({PumlBackend, :puml_backend})
          :hackney_trace.disable()
          Cache.reset(:puml)

          Logger.info("[puml-info] puml generated and offloaded")
        end
      end

      defp opts, do: opts([])

      defp opts(args) do
        config = unquote(Macro.escape(my_opts))
        env_config = Application.get_env(:puml_generator, PumlGenerator.Generator)
        merged_config = Keyword.merge(env_config, config)
        merged_config = Keyword.merge(merged_config, args)

        url_participant_map = map_url_participants(merged_config)
        Keyword.merge(merged_config, url_participant_map: url_participant_map)
      end

      defp map_url_participants(config) do
        config[:url_participant_map]
        |> Enum.map(fn
          {urls, from, to, internal} -> entry(urls, from, to, internal)
          {urls, from, to} -> entry(urls, from, to)
        end)
      end

      def entry(urls, from \\ :actor, to \\ :self, internal \\ false),
        do: do_entry(urls, from, to, internal)

      defp do_entry(urls, from, to, internal) when is_list(urls) do
        %{urls: urls, from: from, to: to, internal: internal}
      end

      defp do_entry(url, from, to, internal) do
        entry([url], from, to, internal)
      end
    end
  end
end
