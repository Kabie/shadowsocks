defmodule ShadowSocksTest.Coder do
  use ExUnit.Case, async: false
  import ShadowSocks.Coder

  test "evp_bytes_to_key" do
    assert evp_bytes_to_key("password", 16, 16) ==
      {<<95, 77, 204, 59, 90, 167, 101, 214, 29, 131, 39, 222, 184, 130, 207, 153>>,
       <<43, 149, 153, 10, 145, 81, 55, 74, 189, 143, 248, 197, 167, 160, 254, 8>>}
  end

  test "encode" do
    {key, iv} = evp_bytes_to_key("password", 16, 16)
    init_coder = {key, iv, ""}
    {coder, c1} = encode("hello", init_coder)
    assert c1 == << 115, 96, 242, 42, 90 >>
    {coder, c2} = encode("world", coder)
    assert c2 == << 77, 83, 51, 103, 112 >>
    {_coder, c3} = encode("some very long text, very, very long", coder)
    assert c3 == << 206, 159, 180, 58, 41, 225, 150, 100,
                    163, 9, 21, 168, 127, 175, 229, 191,
                    31, 196, 164, 235, 118, 141, 239, 155,
                    76, 32, 160, 96, 72, 30, 251, 176,
                    1, 122, 10, 190 >>

    {_, c} = encode("hello" <> "world" <> "some very long text, very, very long", init_coder)
    assert c == c1 <> c2 <> c3
  end

  test "decoder" do
    {key, iv} = evp_bytes_to_key("password", 16, 16)
    init_coder = {key, iv, ""}

    {coder, c1} = decode(<< 115, 96, 242, 42, 90 >>, init_coder)
    assert c1 == "hello"
    {coder, c2} = decode(<< 77, 83, 51, 103, 112 >>, coder)
    assert c2 == "world"
    {_coder, c3} = decode(<<206, 159, 180, 58, 41, 225, 150, 100,
                            163, 9, 21 ,168, 127, 175, 229, 191,
                            31, 196, 164, 235, 118, 141, 239, 155,
                            76, 32, 160, 96, 72, 30, 251, 176,
                            1, 122, 10, 190 >>, coder)
    assert c3 == "some very long text, very, very long"

    {_coder, c} = decode(<< 115, 96, 242, 42, 90 >> <>
                         << 77, 83, 51, 103, 112 >> <>
                         << 206, 159, 180, 58, 41, 225, 150, 100,
                            163, 9, 21 ,168, 127, 175, 229, 191,
                            31, 196, 164, 235, 118, 141, 239, 155,
                            76, 32, 160, 96, 72, 30, 251, 176,
                            1, 122, 10, 190 >>, init_coder)
    assert c == c1 <> c2 <> c3
  end

end
