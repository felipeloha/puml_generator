defmodule PumlGenerator.Cache do
  def init_cache(table) do
    if :ets.info(table) == :undefined do
      :ets.new(table, [:named_table, :public])
    end

    reset(table)
  end

  def reset(table) do
    :ets.delete_all_objects(table)
  end

  def insert(key, item) do
    :ets.insert(:puml, {key, item})
    item
  rescue
    _ ->
      item
  end

  def update_item(key, args) do
    [{_, cache}] = :ets.lookup(:puml, key)
    item = Map.merge(cache, args)
    :ets.insert(:puml, {key, item})
    item
  rescue
    _ ->
      nil
  end

  def get(key) do
    :ets.lookup(:puml, key)
    |> case do
      [] -> nil
      [{_, val}] -> val
    end
  rescue
    _ ->
      nil
  end
end
