defmodule HCIndexer.Mapping do
  @moduledoc """
  Set mapping between `Ecto` model and ElasticSearch field.
  """
  import HCIndexer.Request

  defmacro __using__(_) do
    quote do
      import HCIndexer.Mapping
    end
  end

  @doc """
  Create index with corresponding mapping to server
  """
  @spec create_mapping(atom, map, map) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def create_mapping(index, mapping, settings \\ nil) do
    data = %{mappings: %{Atom.to_string(index) => %{properties: mapping}}}
    data = case is_map(settings) do
      true -> Map.merge(data, %{settings: settings})
      false -> data
    end
    put("#{Atom.to_string(index)}", data)
  end

  @doc """
  Update an already created mapping
  """
  @spec update_mapping(atom, map) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def update_mapping(index, mapping) do
    put("#{Atom.to_string(index)}/_mapping/#{Atom.to_string(index)}", %{
      properties: mapping,
    })
  end

  @doc """
  Get mapping of an index
  """
  @spec fetch_mapping(atom) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} |
    {:error, HTTPoison.Error.t}
  def fetch_mapping(index) do
    get!("#{Atom.to_string(index)}/_mapping/#{Atom.to_string(index)}")
  end

  @doc """
  Define a mapping for a struct. Index name is optionnal, it could be
  auto-guessed from module name

  Using mapping add shorthands (you don't have to specify index) to :
  * `HCIndexer.Mapping.update_mapping/2`
  * `HCIndexer.Mapping.fetch_mapping/1`
  * `HCIndexer.Mapping.create_mapping/2`

  And provide methods to return :
  * index name as `index/0`
  * current mapping's map as `mapping/0`

  Example:
  ```elixir
  defmodule Test.Model do
    defstruct [:a_word, :a_float]
    use HCIndexer.Searchable

    mapping "my_model" do
      property :a_word, :string
      property :a_float, :float
    end
  end
  ```
  """
  @spec mapping(atom, any) :: Macro.t
  defmacro mapping(index \\ nil, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :properties, accumulate: true)

      case unquote(index) do
        nil ->
          index = __MODULE__
            |> Module.split()
            |> List.last()
            |> Macro.underscore()
            |> String.to_atom()

          Module.put_attribute(__MODULE__, :index, index)
        _ ->
          @index unquote(index)
      end

      unquote(block)

      @mapping Enum.reduce(@properties, &Map.merge/2)

      def mapping, do: @mapping
      def index, do: @index

      def update_mapping, do: update_mapping(@index, @mapping)
      def fetch_mapping, do: fetch_mapping(@index)
      def create_mapping, do: create_mapping(@index, @mapping)
    end
  end

  @doc """
  Define a property in a `HCIndexer.Mapping.mapping` block.
  Used to set link a struct field to an ElasticSearch type.

  Example: See `HCIndexer.Mapping.mapping/2`'s doc
  """
  @spec property(atom, atom, Keyword.t) :: Macro.t
  defmacro property(name, type, opts \\ []) when is_atom(name) and is_atom(type) do
    quote do
      property = %{
        unquote(name) => %{
          type: Atom.to_string(unquote(type)),
        } |> Map.merge(Enum.into(unquote(opts), %{})),
      }
      Module.put_attribute(__MODULE__, :properties, property)
    end
  end
end
