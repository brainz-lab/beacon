module Mcp
  class ToolsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_mcp_request

    # GET /mcp/tools
    def index
      render json: {
        tools: Mcp::ToolRegistry.schema
      }
    end

    # POST /mcp/tools/:name
    def call
      tool = Mcp::ToolRegistry.find(params[:name])

      unless tool
        return render json: { error: "Unknown tool: #{params[:name]}" }, status: :not_found
      end

      result = tool.call(tool_params, project: current_project)

      render json: result
    end

    # POST /mcp/rpc
    # JSON-RPC 2.0 compatible endpoint
    def rpc
      request_data = JSON.parse(request.body.read)

      case request_data["method"]
      when "tools/list"
        render json: {
          jsonrpc: "2.0",
          id: request_data["id"],
          result: { tools: Mcp::ToolRegistry.schema }
        }
      when "tools/call"
        tool_name = request_data.dig("params", "name")
        arguments = request_data.dig("params", "arguments") || {}

        tool = Mcp::ToolRegistry.find(tool_name)

        unless tool
          return render json: {
            jsonrpc: "2.0",
            id: request_data["id"],
            error: { code: -32601, message: "Unknown tool: #{tool_name}" }
          }
        end

        result = tool.call(arguments.symbolize_keys, project: current_project)

        render json: {
          jsonrpc: "2.0",
          id: request_data["id"],
          result: { content: [ { type: "text", text: result.to_json } ] }
        }
      else
        render json: {
          jsonrpc: "2.0",
          id: request_data["id"],
          error: { code: -32601, message: "Method not found" }
        }
      end
    rescue JSON::ParserError
      render json: {
        jsonrpc: "2.0",
        id: nil,
        error: { code: -32700, message: "Parse error" }
      }, status: :bad_request
    end

    private

    def authenticate_mcp_request
      api_key = request.headers["X-API-Key"] || params[:api_key]

      unless api_key.present?
        return render json: { error: "API key required" }, status: :unauthorized
      end

      @current_project = Project.find_by(api_key: api_key)

      unless @current_project
        render json: { error: "Invalid API key" }, status: :unauthorized
      end
    end

    def current_project
      @current_project
    end

    def tool_params
      params.except(:controller, :action, :name, :api_key).permit!.to_h.symbolize_keys
    end
  end
end
