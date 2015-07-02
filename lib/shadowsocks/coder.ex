defmodule ShadowSocks.Coder do

  @doc """
  Equivalent to OpenSSL's `EVP_BytesToKey()` with count 1
  """
  def evp_bytes_to_key(password, key_len, iv_len) do
    _evp_bytes_to_key(password, key_len, iv_len, "")
  end
  
  defp _evp_bytes_to_key(password, key_len, iv_len, bytes) do
    case bytes do
      <<key::binary-size(key_len), iv::binary-size(iv_len), _::binary>> ->
        {key, iv}
      _ ->
        _evp_bytes_to_key(password, key_len, iv_len,
          bytes <> :erlang.md5(bytes <> password))
    end
  end

end
