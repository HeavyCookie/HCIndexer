defmodule HCIndexer.Index do
  @moduledoc """
  Manage document indexation
  """
  import HCIndexer.Request
  @callback to_elasticsearch(Map.t) :: Map.t

  defmacro __using__(_) do
    quote do
      import HCIndexer.Index
      @derive {Poison.Encoder, except: [:__meta__]}

      def index(document) when is_map(document) do
        index(index(), document)
      end

      def index(documents) when is_list(documents) do
        bulk_index(index(), documents)
      end
    end
  end

  def index(index, %{id: id} = document),
    do: put("#{Atom.to_string(index)}/#{Atom.to_string(index)}/#{id}", document)

  def index(index, documents)
    when is_list(documents),
    do: bulk_index(index, documents)

  def bulk_index(index, documents) do
    transform_function = fetch_transform_function(List.first(documents))

    documents
    |> Enum.map(fn document ->
      header = %{index: %{_index: index, _type: index, _id: document.id}}
        |> Poison.encode!()

      encoded_document = transform_function.(document)
        |> Poison.encode!()

      header <> "\n" <> encoded_document
    end)
    |> Enum.chunk(500, 500, [])
    |> Enum.each(fn chunk ->
      body = chunk
        |> Enum.join("\n")
      request(:post, "#{Atom.to_string(index)}/#{Atom.to_string(index)}/_bulk",
              body, [{"Content-Type", "application/x-ndjson"}])
    end)
  end

  defp fetch_transform_function(struct) do
    case Map.get(struct, :__struct__) do
      nil -> nil
      module ->
        if Kernel.function_exported?(module, :search_data, 1) do
          &module.search_data/1
        else
          false
        end
    end
  end
end
