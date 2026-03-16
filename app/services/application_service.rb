class ApplicationService
  attr_reader :errors, :input, :output

  def initialize(input = {})
    @called = false
    @errors = []
    @input = input
    @output = {}

    yield if block_given?
  end

  def call
    self.called = true

    begin
      yield if block_given?
    rescue ServiceError => error
      add_error(error.message)
    end

    success?
  end

  def called?
    called
  end

  def success?
    called? && errors.none?
  end

  private

  attr_accessor :called
  attr_writer :errors, :input, :output

  def add_error(message)
    self.errors << {
      message: message
    }
  end
end
