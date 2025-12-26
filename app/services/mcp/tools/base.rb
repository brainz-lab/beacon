module Mcp
  module Tools
    class Base
      class << self
        def name
          raise NotImplementedError
        end

        def description
          raise NotImplementedError
        end

        def parameters
          {}
        end

        def call(params, project:)
          new(project).execute(params)
        end
      end

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def execute(params)
        raise NotImplementedError
      end

      protected

      def success(data)
        { success: true, data: data }
      end

      def error(message)
        { success: false, error: message }
      end
    end
  end
end
