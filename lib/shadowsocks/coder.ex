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

  defp collect(<<block::binary-size(16), rest::binary>>, blocks) do
    collect(rest, blocks <> block)
  end

  defp collect(bytes, blocks), do: {bytes, blocks}

  # TODO: refactoring
  def encode(bytes, {key, iv, buffer}) do
    txt_len = :erlang.size bytes
    buf_len = :erlang.size buffer
    total = buffer <> bytes
    blk_len = div(:erlang.size(total), 16) * 16
    << blocks :: binary-size(blk_len), rest :: binary >> = total

    encoded_blocks = :crypto.block_encrypt :aes_cfb128, key, iv, blocks
    new_iv = iv <> encoded_blocks
    new_iv = :erlang.binary_part(new_iv, :erlang.size(new_iv), -16)
    encoded_rest = :crypto.block_encrypt :aes_cfb128, key, new_iv, rest
    encoded = encoded_blocks <> encoded_rest
    result = :erlang.binary_part(encoded, buf_len, txt_len)
    {{key, new_iv, rest}, result}
  end

  def decode(bytes, {key, iv, buffer}) do
    txt_len = :erlang.size bytes
    buf_len = :erlang.size buffer
    total = buffer <> bytes
    blk_len = div(:erlang.size(total), 16) * 16
    << blocks :: binary-size(blk_len), rest :: binary >> = total

    decoded_blocks = :crypto.block_decrypt :aes_cfb128, key, iv, blocks
    new_iv = iv <> blocks
    new_iv = :erlang.binary_part(new_iv, :erlang.size(new_iv), -16)
    decoded_rest = :crypto.block_decrypt :aes_cfb128, key, new_iv, rest
    decoded = decoded_blocks <> decoded_rest
    result = :erlang.binary_part(decoded, buf_len, txt_len)
    {{key, new_iv, rest}, result}
  end

end
