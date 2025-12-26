module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_project_id

    def connect
      self.current_project_id = find_verified_project
    end

    private

    def find_verified_project
      # Allow connections in development or with valid session
      if Rails.env.development?
        Project.first&.id || reject_unauthorized_connection
      elsif (project_id = cookies.signed[:project_id])
        project_id
      else
        reject_unauthorized_connection
      end
    end
  end
end
