# Prefer an application's native JSON gem over the bundled pure Ruby fallback.
unless defined?(JSON::JSON_LOADED)
  begin
    gem 'json'
  rescue Gem::LoadError
    # Bundler only exposes json when the application explicitly includes it.
  end

  # Both gems provide json.rb and json/common.rb. RubyGems may have activated
  # our pure dependency first; let the native gem or stdlib supply those files.
  if (pure_json = Gem.loaded_specs['json_pure'])
    paths = pure_json.full_require_paths
    $LOAD_PATH.replace(($LOAD_PATH - paths) + paths)
  end

  begin
    require 'json'
  rescue LoadError
    gem 'json_pure', '= 2.7.6'
    require 'json/common'
    require 'json/pure/parser'
    require 'json/pure/generator'

    # A failed native load can leave newer json/common code in place. Adapt its
    # class entry points without reloading or replacing the global JSON module.
    class JSON::Pure::Parser
      def self.parse(source, options = nil)
        new(source, options).parse
      end
    end

    class JSON::Pure::Generator::State
      class << self
        attr_accessor :default_sort_keys_proc

        def generate(object, options = nil, io = nil)
          result = new(options || {}).generate(object)
          return result unless io

          io.write(result)
          io
        end
      end
    end

    require 'json/pure'
    # Other libraries may require JSON again after the native entry point failed.
    $LOADED_FEATURES << 'json.rb' unless $LOADED_FEATURES.include?('json.rb')
  end
end
