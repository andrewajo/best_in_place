module BestInPlace
  module ControllerExtensions
    def respond_with_bip(obj)
      obj.changed? ? respond_bip_error(obj) : respond_bip_ok(obj)
    end

  private
    def respond_bip_ok(obj)
      klass = obj.class.to_s
      updating_attr = params[klass.underscore].keys.first
      single_renderer, siblings = renderers(klass, updating_attr)
      if siblings.nil?
        if single_renderer
          render :json => single_renderer.render_json(obj)
        else
          head :ok
        end
      else
        siblings << updating_attr
        render :json => BestInPlace::DisplayMethods.render_multiple(obj, klass, siblings)
      end
    end

    def respond_bip_error(obj)
      render :json => obj.errors.full_messages, :status => :unprocessable_entity
    end
    
    def renderers klass, updating_attr
      [BestInPlace::DisplayMethods.lookup(klass, updating_attr), BestInPlace::DisplayMethods.lookup_siblings(klass, updating_attr)]
    end
    
  end
end
