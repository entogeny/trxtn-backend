module Base
  class FindService < ApplicationService
    def call
      super do
        find
        validate
      end
    end

    private

    attr_reader :record

    def find
      find_by_id
      find_by_slug
    end

    def find_by_id
      @record ||= base_scope.find_by(id: input[:identifier])
    end

    def find_by_slug
      if !(@record.nil? && model.attribute_method?(:slug))
        return
      end

      @record = base_scope.find_by(slug: input[:identifier])
    end

    def base_scope
      model.include?(SoftDeletable) ? model.not_soft_deleted : model.all
    end

    def model
      # NOTE: Must be overwritten by inheriting services with the record's model class.
      #   e.g. If you were to do Example.new, it should return Example.
      raise MissingDefinitionError.new("#model must be implemented")
    end

    def validate
      validate_presence
    end

    def validate_presence
      if @record.nil?
        raise ServiceError.new("Unable to find record by identifier: #{input[:identifier]}")
      end

      self.output = { record: @record }
    end
  end
end
