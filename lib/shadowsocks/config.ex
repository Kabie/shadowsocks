defmodule ShadowSocks.Config do
  def int(name, default) do
    case System.get_env(name) do
      nil -> default
      value -> String.to_integer value
    end
  end
  
  def string(name, default) do
    System.get_env(name) || default
  end
end
