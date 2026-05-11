module Hive
  class CompactSigner
    class Rbsecp256k1
      HEADER_BASE = 27
      COMPRESSED_FLAG = 4

      def initialize
        require 'rbsecp256k1'

        unless Secp256k1.have_recovery?
          raise Hive::BaseError, 'rbsecp256k1 was built without recoverable signature support'
        end

        @context = Secp256k1::Context.create
      rescue LoadError => e
        raise Hive::BaseError, "rbsecp256k1 is not available: #{e.message}"
      end

      def sign_compact(digest32, private_key_hex, public_key_hex = nil, compressed = false)
        private_key = Secp256k1::PrivateKey.from_data([private_key_hex].pack('H*'))
        signature = @context.sign_recoverable(private_key, digest32)
        compact_signature, recovery_id = signature.compact
        header = HEADER_BASE + recovery_id + (compressed ? COMPRESSED_FLAG : 0)
        compact = [header].pack('C') + compact_signature

        if public_key_hex && public_key_hex != recover_compact(digest32, compact)
          raise Hive::BaseError, 'Compact signature recovered unexpected public key'
        end

        compact
      end

      def recover_compact(digest32, compact_signature)
        header = compact_signature.bytes.first
        recovery_id = header - HEADER_BASE
        recovery_id -= COMPRESSED_FLAG if recovery_id >= COMPRESSED_FLAG
        signature = @context.recoverable_signature_from_compact(compact_signature.byteslice(1, 64), recovery_id)

        signature.recover_public_key(digest32).uncompressed.unpack1('H*')
      end

      def public_key(private_key_hex, compressed = false)
        keypair = @context.key_pair_from_private_key([private_key_hex].pack('H*'))
        public_key = keypair.public_key

        (compressed ? public_key.compressed : public_key.uncompressed).unpack1('H*')
      end
    end

    def self.default
      @default ||= Rbsecp256k1.new
    end
  end
end
