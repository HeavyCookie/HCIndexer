defmodule HCIndexer.Index do
  @moduledoc """
  Manage document indexation
  """
  import HCIndexer.Request
  alias HCIndexer.Alias
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

  @doc """
  Add a document in an index
  """
  @spec index(atom, map | list) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def index(index, %{id: id} = document),
    do: put("#{Atom.to_string(index)}/#{Atom.to_string(index)}/#{id}", document)

  def index(index, documents)
    when is_list(documents),
    do: bulk_index(index, documents)


  @doc """
  Add a document in an index
  """
  @spec index(atom, list) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
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

  @doc """
  Create an index with an alias to ease reindexing procedure
  """
  @spec create_index_alias(Atom.t) :: HTTPoison.Response.t
  def create_index_alias(index) do
    name = Atom.to_string(index)
    put!("#{get_dated_index_name(name)}/_alias/#{name}")
  end

  @doc """
  Return a name followed by ISO8601 date
  """
  @spec get_dated_index_name(String.t | Atom.t) :: String.t
  def get_dated_index_name(index) when is_atom(index) do
    Atom.to_string(index) |> get_dated_index_name()
  end

  def get_dated_index_name(index) when is_binary(index) do
    date = DateTime.utc_now()
      |> DateTime.to_iso8601(:basic)
      |> String.replace(~r/[^\d]/, "_")
    "#{index}_#{date}"
  end

  @doc """
  Create an index from a struct using `HCIndexer.Searchable`
  """
  @spec create(module) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def create(module) do
    create(module.index, module.mapping, module.search_settings)
  end

  @doc """
  Create an index, override previous one if exists
  """
  @spec create(atom, map, map) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def create(index, properties, settings \\ nil) do
    # Delete previous existing index
    index
    |> Atom.to_string()
    |> Alias.list_index()
    |> Enum.map(&delete/1)
    # Create index with mapping & settings
    data = %{
      mappings: %{
        index => %{
          _all: %{ enabled: false }, # index only mapped attributes
          properties: properties,
        }
      },
      settings: settings,
      aliases: %{ index => %{} }, # Create index alias with base index name
    }
    real_index_name = get_dated_index_name(index)
    Alias.delete_all(index)
    {real_index_name, put(real_index_name, data)} # Create index with a dated name
  end

  @doc """
  Remove an index
  """
  @spec remove(String.t) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def remove(name) do
    delete name
  end
end
