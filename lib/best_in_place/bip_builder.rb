module BestInPlace
  class BipBuilder
    
    def initialize object, template, tag=nil, condition=true, options={}
      @object = object
      @template = template
      @tag = tag
      @condition = condition
      @options = options
    end
    
    [:input, :textarea, :select, :checkbox, :date, :no_edit, :date].each{ |method| define_method(method){ |field, *opts| bip(method, field, *opts) }}
    
    def best_in_place field, opts={}
      if opts[:display_as] && opts[:display_with]
        raise ArgumentError, "Can't use both 'display_as' and 'display_with' options at the same time"
      end

      #if opts[:display_with] && !ViewHelpers.respond_to?(opts[:display_with])
      #  raise ArgumentError, "Can't find helper #{opts[:display_with]}"
      #end

      opts[:type] ||= :input
      opts[:collection] ||= []
      field = field.to_s
      
      if opts[:update_with]
        BestInPlace::DisplayMethods.add_sibling_attributes(@object.class.to_s, field, opts[:update_with])
      end

      value = build_value_for(field, opts)

      collection = nil
      if opts[:type] == :select && !opts[:collection].blank?
        v = @object.send(field)
        value = Hash[opts[:collection]][!!(v =~ /^[0-9]+$/) ? v.to_i : v]
        collection = opts[:collection].to_json
      end
      if opts[:type] == :checkbox
        fieldValue = !!@object.send(field)
        if opts[:collection].blank? || opts[:collection].size != 2
          opts[:collection] = ["No", "Yes"]
        end
        value = fieldValue ? opts[:collection][1] : opts[:collection][0]
        collection = opts[:collection].to_json
      end
      out = "<span class='best_in_place#{opts[:type] == :no_edit ? '_no_edit' : nil}'"
      out << " id='#{BestInPlace::Utils.build_best_in_place_id(@object, field)}'"
      out << " data-url='#{opts[:path].blank? ? url_for(@object) : url_for(opts[:path])}'" unless opts[:type] == :no_edit
      out << " data-object='#{@object.class.to_s.gsub("::", "_").underscore}'"
      out << " data-collection='#{collection.gsub(/'/, "&#39;")}'" unless collection.blank?
      out << " data-attribute='#{field}'"
      out << " data-activator='#{opts[:activator]}'" unless opts[:activator].blank?
      out << " data-nil='#{opts[:nil]}'" unless opts[:nil].blank?
      out << " data-type='#{opts[:type]}'" unless opts[:type] == :no_edit
      out << " data-inner-class='#{opts[:inner_class]}'" if opts[:inner_class]
      out << " data-html-attrs='#{opts[:html_attrs].to_json}'" unless opts[:html_attrs].blank?
      out << " data-original-content='#{@object.send(field)}'" if opts[:display_as] || opts[:display_with]
      if !opts[:sanitize].nil? && !opts[:sanitize]
        out << " data-sanitize='false'>"
        out << sanitize(value, :tags => %w(b i u s a strong em p h1 h2 h3 h4 h5 ul li ol hr pre span img br), :attributes => %w(id class href))
      else
        out << ">#{sanitize(value, :tags => nil, :attributes => nil)}"
      end
      out << "</span>"
      raw out
    end
    
    def best_in_place_if(condition, field, opts={})
      opts.merge!(:type => :no_edit) unless condition
      best_in_place(field, opts)
    end
    
  protected
    
    def bip method, field, opts={}
      method = :no_edit unless @condition
      opts.merge!(:type => method)
      tag do
        opts.has_key?(:if) ? best_in_place_if(opts[:if], field, opts) : best_in_place(field, opts)
      end
    end
    
    def tag &block
      return yield unless @tag
      content_tag @tag, @options do
        yield
      end
    end
    
    def build_value_for(field, opts)
      if opts[:display_as]
        BestInPlace::DisplayMethods.add_model_method(@object.class.to_s, field, opts[:display_as])
        @object.send(opts[:display_as]).to_s

      elsif opts[:display_with]
        BestInPlace::DisplayMethods.add_helper_method(@object.class.to_s, field, opts[:display_with])
        if ViewHelpers.respond_to?(opts[:display_with])
          BestInPlace::ViewHelpers.send(opts[:display_with], @object.send(field))
        else
          @template.send opts[:display_with], @object.send(field)
        end

      else
        @object.send(field).to_s.presence || ""
      end
    end
    
    def method_missing *args, &block
      @template.send *args, &block
    end
    
  end
end