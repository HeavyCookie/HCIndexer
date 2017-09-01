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

  def create_mapping(index, mapping, settings \\ nil) do
    data = %{mappings: %{Atom.to_string(index) => %{properties: mapping}}}
    data = case is_map(settings) do
      true -> Map.merge(data, %{settings: settings})
      false -> data
    end
    put("#{Atom.to_string(index)}", data)
  end

  def update_mapping(index, mapping) do
    put("#{Atom.to_string(index)}/_mapping/#{Atom.to_string(index)}", %{
      properties: mapping,
    })
  end

  def fetch_mapping(index) do
    get("#{Atom.to_string(index)}/_mapping/#{Atom.to_string(index)}")
  end

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
