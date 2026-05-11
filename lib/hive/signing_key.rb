module Hive
  class SigningKey
    PRIVATE_KEY_VERSION = '80'
    COMPRESSED_FLAG = '01'

    attr_reader :private_key_hex, :compressed

    def self.from_base58(wif)
      new(wif)
    end

    def initialize(wif)
      hex = Bitcoin.decode_base58(wif)
      compressed = hex.size == 76
      version, private_key_hex, flag, checksum = hex.unpack("a2a64a#{compressed ? 2 : 0}a8")

      raise Hive::ArgumentError, 'Invalid private key version' unless version == PRIVATE_KEY_VERSION
      raise Hive::ArgumentError, 'Invalid compressed private key flag' if compressed && flag != COMPRESSED_FLAG
      raise Hive::ArgumentError, 'Invalid private key checksum' unless Bitcoin.checksum(version + private_key_hex + flag) == checksum

      @private_key_hex = private_key_hex
      @compressed = compressed
    end

    def pub
      CompactSigner.default.public_key(private_key_hex, compressed)
    end
  end
end
