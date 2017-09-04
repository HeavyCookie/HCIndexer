require Logger

defmodule HCIndexer.Alias do
  import HCIndexer.Request

  def aliased_index(name) do
    case get("#{name}/_aliases") do
      {:err, _} ->
        []
      result ->
        result.body |> Poison.decode!() |> Map.keys()
    end
  end

  def delete_all(name) do
    actions = name
      |> aliased_index()
      |> Enum.map &(%{ "remove" => %{ "index" => &1, "alias" => name}})

    post "_aliases", %{ "actions" => actions }
  end
end
