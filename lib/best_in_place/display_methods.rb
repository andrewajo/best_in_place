module BestInPlace
  module DisplayMethods
    extend self

    class Renderer < Struct.new(:opts)
      
      def render_json object
        resp = {:original_value => object.send(opts[:attr])}
        case opts[:type]
        when :model
          resp[:display_as] = object.send(opts[:method])
        when :helper
          resp[:display_as] = BestInPlace::ViewHelpers.send(opts[:method], object.send(opts[:attr]))
        end
        resp.to_json
      end
      
    end

    @@table = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
    @@update_with_table = Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }

    def lookup(klass, attr)
      foo = @@table[klass.to_s][attr.to_s]
      foo == {} ? nil : foo
    end

    def add_model_method(klass, attr, display_as)
      @@table[klass.to_s][attr.to_s] = Renderer.new :method => display_as.to_sym, :type => :model, :attr => attr
    end

    def add_helper_method(klass, attr, helper_method)
      @@table[klass.to_s][attr.to_s] = Renderer.new :method => helper_method.to_sym, :type => :helper, :attr => attr
    end
    
    def add_sibling_attributes(klass, attr, siblings)
      @@update_with_table[klass.to_s][attr.to_s] = Array(siblings).map(&:to_sym)
    end
    
    def lookup_siblings klass, attr
      foo = @@update_with_table[klass.to_s][attr.to_s]
      foo == {} ? nil : foo
    end
    
    def render_multiple obj, klass, attributes
      Hash[ attributes.map{ |attr| [attr, (lookup(klass, attr).nil? ? Renderer.new(:attr => attr) : lookup(klass, attr))] }.map{ |k, v| [k, v.render_json(obj)]} ].to_json
    end
    
  end
end
