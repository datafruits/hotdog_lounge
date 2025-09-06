defmodule HotdogLounge.Token do
  use Joken.Config

  @impl true
  def token_config do
    default_claims(skip: [:aud])
  end
end

