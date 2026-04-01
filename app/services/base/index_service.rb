module Base
  class IndexService < ApplicationService

    PAGINATION_DEFAULTS = {
      page_number: 1,
      page_size: 10
    }.freeze

    def call
      super do
        load_all
        search
        filter
        order
        paginate
      end
    end

    private

    attr_reader :records

    def base_scope
      model.include?(SoftDeletable) ? model.not_soft_deleted : model.all
    end

    def filter
      # NOTE: Does nothing by default. Inheritors can redefine / extend as needed.
      #  e.g.
      #  def filter
      #    filter_by_alfa
      #    filter_by_beta
      #  end
    end

    def filter_params
      @input[:filter] || {}
    end

    def load_all
      @records = base_scope
    end

    def model
      # NOTE: Must be overwritten by inheriting services with the record's model class.
      #   If you were to do Example.new, it should return Example.
      raise MissingDefinitionError.new("#model must be implemented")
    end

    def order
      # NOTE: Does nothing by default. Inheritors can redefine to apply a sort order.
      #  e.g.
      #  def order
      #    @records = @records.order(created_at: :desc)
      #  end
    end

    def paginate
      page_number = pagination_params[:page_number] || PAGINATION_DEFAULTS[:page_number]
      page_size = pagination_params[:page_size] || PAGINATION_DEFAULTS[:page_size]

      @records = records.page(page_number).per(page_size)
      self.output = { records: @records }
    end

    def pagination_params
      @input[:pagination] || {}
    end

    def search
      # NOTE: Does nothing by default. Inheritors can redefine / extend as needed.
      #  e.g.
      #  def search
      #    search_by_alfa
      #    search_by_beta
      #  end
    end

    def search_params
      @input[:search] || {}
    end

  end
end
