require 'base58'
require 'digest/sha2'

module Hive
  class SigningKey
    PRIVATE_KEY_VERSION = '80'
    COMPRESSED_FLAG = '01'

    attr_reader :private_key_hex, :compressed

    def self.from_base58(wif)
      new(wif)
    end

    def initialize(wif)
      unless wif.is_a?(String) && (51..52).cover?(wif.bytesize)
        raise Hive::ArgumentError, 'Invalid private key length'
      end

      begin
        bytes = Base58.base58_to_binary(wif, :bitcoin)
      rescue ::ArgumentError
        raise Hive::ArgumentError, 'Invalid private key encoding'
      end

      raise Hive::ArgumentError, 'Invalid private key length' unless [37, 38].include?(bytes.bytesize)

      hex = bytes.unpack('H*').first
      compressed = hex.size == 76
      version, private_key_hex, flag, checksum = hex.unpack("a2a64a#{compressed ? 2 : 0}a8")

      raise Hive::ArgumentError, 'Invalid private key version' unless version == PRIVATE_KEY_VERSION
      raise Hive::ArgumentError, 'Invalid compressed private key flag' if compressed && flag != COMPRESSED_FLAG
      expected_checksum = Digest::SHA256.hexdigest(Digest::SHA256.digest(bytes[0...-4]))[0...8]
      raise Hive::ArgumentError, 'Invalid private key checksum' unless expected_checksum == checksum

      @private_key_hex = private_key_hex
      @compressed = compressed
    end

    def pub
      CompactSigner.default.public_key(private_key_hex, compressed)
    end
  end
end
