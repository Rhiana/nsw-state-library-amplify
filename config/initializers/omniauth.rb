Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'],
                           ENV['GOOGLE_CLIENT_SECRET'],
                           skip_jwt: true
  provider :facebook, ENV['FACEBOOK_APP_ID'],
                      ENV['FACEBOOK_APP_SECRET']
  provider :gigya, ENV['GIGYA_CLIENT_ID'],
                   ENV['GIGYA_CLIENT_SECRET'],
                   screen_set: 'SLNSW-RegistrationLogin',
                   mobile_screen_set: 'SLNSW-RegistrationLogin',
                   start_screen: 'gigya-login-screen'
end

# Uses custom markup and CSS for login form.
# @see https://medium.com/makit/styling-omniauth-forms-using-rails-asset-pipeline-6af352025e53
module OmniAuth
  class PageWithoutForm < OmniAuth::Form

    # def header(title, header_info)
    #   @html << <<-HTML
    #   <!DOCTYPE html>
    #   <html>
    #   <head>
    #     <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    #     <title>#{title}</title>
    #     #{css}
    #     #{header_info}
    #   </head>
    #   <body>
    #   <!-- <h1>#{title}</h1> -->
    #   HTML
    #   self
    # end

    # def footer
    #   return self if @footer
    #   @html << <<-HTML
    #   </body>
    #   </html>
    #   HTML
    #   @footer = true
    #   self
    # end

    protected

    def css
      h = ActionController::Base.helpers
      h.stylesheet_link_tag('/assets/css/login', media: 'all')
    end
  end
end
