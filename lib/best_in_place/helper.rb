module BestInPlace
  module BestInPlaceHelpers

    def best_in_place object, tag_or_field=nil, opts={}
      builder = BestInPlace::BipBuilder.new(object, self, tag_or_field, true, opts)
      block_given? ? yield(builder) : builder.best_in_place(tag_or_field, opts)
    end

    def best_in_place_if condition, object, tag_or_field=nil, opts={}
      builder = BestInPlace::BipBuilder.new(object, self, tag_or_field, condition, opts)
      block_given? ? yield(builder) : builder.best_in_place_if(condition, tag_or_field, opts)
    end

  end
end

