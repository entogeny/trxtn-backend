# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Enforces the use of `if !condition` over `unless condition`.
      #
      # @example
      #   # bad
      #   unless condition
      #     do_something
      #   end
      #
      #   # bad (modifier form)
      #   do_something unless condition
      #
      #   # good
      #   if !condition
      #     do_something
      #   end
      #
      #   # good (modifier form)
      #   do_something if !condition
      class NoUnless < Base
        extend AutoCorrector

        MSG = "Use `if !condition` instead of `unless condition`."

        def on_if(node)
          return if !(node.unless?)

          add_offense(node.loc.keyword) do |corrector|
            corrector.replace(node.loc.keyword, "if")

            condition = node.condition
            if condition.and_type? || condition.or_type?
              corrector.insert_before(condition.source_range, "!(")
              corrector.insert_after(condition.source_range, ")")
            else
              corrector.insert_before(condition.source_range, "!")
            end
          end
        end
      end
    end
  end
end
