require 'test_helper'

module Hive
  class MarshalIntegerTest < Hive::Test
    def test_integer_values_and_cursor
      {
        unsigned_char: ['ff', 255], signed_char: ['ff', -1],
        uint16: ['feff', 65534], int16: ['feff', -2],
        uint32: ['fdffffff', 4294967293], int32: ['fdffffff', -3],
        uint64: ['fcffffffffffffff', 18446744073709551612], int64: ['fcffffffffffffff', -4]
      }.each do |method, (hex, expected)|
        marshal = Marshal.new(hex: '00' + hex + '7f')
        marshal.step(1)
        assert_equal expected, marshal.public_send(method), method.to_s
        assert_equal 1 + hex.size / 2, marshal.cursor
        assert_equal 127, marshal.unsigned_char
      end
    end

    def test_truncated_integers_raise_after_advancing_the_cursor
      {unsigned_char: 1, signed_char: 1, uint16: 2, int16: 2,
       uint32: 4, int32: 4, uint64: 8, int64: 8}.each do |method, length|
        length.times do |available|
          marshal = Marshal.new(bytes: "\0" * available)
          error_class, message = available.zero? ? [EOFError, 'End of file reached'] : [IOError, 'data truncated']
          error = assert_raises(error_class) { marshal.public_send(method) }
          assert_equal message, error.message
          assert_equal length, marshal.cursor
        end
      end
    end
  end
end
