module Hive
  module Utils
    def hexlify(s)
      return s.unpack('H*').first if s.is_a?(String)

      bytes = s.to_enum(s.respond_to?(:each_byte) ? :each_byte : :each)
      bytes.map { |byte| '%02x' % byte }.join
    end
    
    def unhexlify(s)
      s.split.pack('H*')
    end
  end
end
