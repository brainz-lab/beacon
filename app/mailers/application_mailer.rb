class ApplicationMailer < ActionMailer::Base
  default from: "Beacon Status <status@brainzlab.ai>"
  layout "mailer"
end
