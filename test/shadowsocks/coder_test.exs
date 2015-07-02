defmodule ShadowSocksTest.Coder do
  use ExUnit.Case
  import ShadowSocks.Coder

  test "evp_bytes_to_key" do
    assert evp_bytes_to_key("password", 16, 16) ==
      {<<95, 77, 204, 59, 90, 167, 101, 214, 29, 131, 39, 222, 184, 130, 207, 153>>,
       <<43, 149, 153, 10, 145, 81, 55, 74, 189, 143, 248, 197, 167, 160, 254, 8>>}
  end
end
