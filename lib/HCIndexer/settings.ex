defmodule HCIndexer.Settings do
  @moduledoc """
  Change index settings
  """
  import HCIndexer.Request

  defmacro __using__(_) do
    quote do
      import HCIndexer.Settings
    end
  end

  defmacro search_settings(settings) do
    quote do
      def search_settings, do: unquote(settings)
    end
  end

  def create_settings(index, settings) do
    put("#{Atom.to_string(index)}", %{
      settings: settings,
    })
  end

  def update_settings(index, settings) do
    url_index = "#{Atom.to_string(index)}"
    post("#{url_index}/_close")
    put("#{url_index}/_settings", settings)
    post("#{url_index}/_open")
  end

  def autocomplete do
    %{
      "analysis": %{
        "filter": %{
          "autocomplete_filter": %{
            "type": "edge_ngram",
            "min_gram": 1,
            "max_gram": 20
          }
        },
        "analyzer": %{
          "autocomplete": %{
            "type": "custom",
            "tokenizer": "standard",
            "filter": [
              "lowercase",
              "asciifolding",
              "autocomplete_filter",
            ]
          }
        }
      }
    }
  end
end
