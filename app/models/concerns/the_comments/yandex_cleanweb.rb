module TheComments
  module YandexCleanweb
    private

    def cleanweb_antispam_check request_data
      comment = self
      ycw_key = ::TheComments.config.yandex_cleanweb_api_key

      if ycw_key.present?
        data = cleanweb_html_data(comment, request_data)
        cleanweb_check(comment, ycw_key, data)
      end
    end

    def cleanweb_html_data comment, request_data
      name  = comment.try(:user).try(:username) || comment.contacts
      email = comment.try(:user).try(:email) || comment.contacts
      email = nil unless email.to_s.match ::TheComments::EMAIL_REGEXP

      {
        name:  name,
        email: email,
        ip:    request_data.try(:[], :ip),
        body_html: comment.content,
        login: comment.try(:user).try(:login)
      }.compact
    end

    def cleanweb_check comment, ycw_key, data
      ::YandexCleanweb.api_key = ycw_key

      if result = ::YandexCleanweb.spam?(data)
        ya_id = result.try(:[], :id)
        comment.update_columns(
          yandex_cleanweb_id: ya_id,
          yandex_cleanweb_state: :spam
        )
      end
    end
  end
end

