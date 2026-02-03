# Force BaseController to be loaded during Rails initialization
# This prevents Zeitwerk alphabetical eager loading order issues
require Rails.root.join('app/controllers/api/v1/base_controller')
