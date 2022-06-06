class AdminMailer < ActionMailer::Base
  default from: ->(email){ Site.email_from }

  def threshold_email_reminder(admin_users, petitions)
    @petitions = petitions
    mail(subject: "Petitions alert", to: admin_users.map(&:email))
  end

  def notify_admin_of_petition_created(new_petition)
    @new_petition = new_petition
    subject = subject_for(:petition_created)
    recipient_email = "partiolaisaloite@partio.fi"
    mail to: recipient_email , subject: subject
  end

  def subject_for(key, options = {})
    I18n.t key, i18n_options.merge(options)
  end

  def i18n_options
    {}.tap do |options|
      options[:scope] = :"mail.admin"

      if defined?(@subject)
        options[:subject] = @subject
      end
    end
  end
end
