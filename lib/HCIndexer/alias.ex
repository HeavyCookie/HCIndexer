require Logger

defmodule HCIndexer.Alias do
  import HCIndexer.Request

  def list_index(name) do
    case get("#{name}/_aliases") do
      {:err, _} ->
        []
      {:ok, result} ->
        Map.keys(result)
    end
  end

  def delete_all(name) do
    actions = name
      |> list_index()
      |> Enum.map &(%{ "remove" => %{ "index" => &1, "alias" => name}})

    post "_aliases", %{ "actions" => actions }
  end
end
