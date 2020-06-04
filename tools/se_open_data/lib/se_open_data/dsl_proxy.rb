module SeOpenData
  # A mechanism to hide implementation from the DSL
  # by closing over variables.
  #
  # FIXME give an example.
  class DslProxy
    def initialize(**attrs)
      attrs.each do |key, val|
        raise "parameter key '#{key}' must have a callable value" unless
          val.respond_to? :call

        #puts "defining proxy method #{key}"
        method = key.to_sym
        define_singleton_method method do |*args, **kargs, &block|
          #puts ">> a #{args} k #{kargs} b #{block}"
          val.call(*args, **kargs, &block)
        end
      end
    end
  end
end
