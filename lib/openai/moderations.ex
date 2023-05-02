defmodule OpenAI.Moderations do
  @moduledoc false
  alias OpenAI.Client
  alias OpenAI.Config

  @moderations_base_url "/moderations"

  def url(), do: @moderations_base_url

  def fetch(params, config \\ %Config{}) do
    url()
    |> Client.api_post(params, config)
  end
end
