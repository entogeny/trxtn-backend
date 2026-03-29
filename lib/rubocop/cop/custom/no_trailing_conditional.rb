# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Enforces block form conditionals over trailing/modifier form.
      #
      # @example
      #   # bad
      #   do_something if condition
      #
      #   # bad
      #   do_something unless condition
      #
      #   # good
      #   if condition
      #     do_something
      #   end
      #
      #   # good
      #   if !condition
      #     do_something
      #   end
      class NoTrailingConditional < Base

        extend AutoCorrector

        MSG = "Use block form instead of trailing `%<keyword>s`."

        def on_if(node)
          if !node.modifier_form?
            return
          end

          keyword = node.loc.keyword.source
          add_offense(node.loc.keyword, message: format(MSG, keyword: keyword)) do |corrector|
            indent = " " * node.source_range.column
            body = (node.if_branch || node.else_branch).source
            condition = node.condition.source

            if_keyword = node.unless? ? "if !#{condition}" : "if #{condition}"

            replacement = "#{if_keyword}\n#{indent}  #{body}\n#{indent}end"
            corrector.replace(node.source_range, replacement)
          end
        end

      end
    end
  end
end
