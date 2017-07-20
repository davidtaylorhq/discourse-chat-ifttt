# name: discourse-chat-ifttt
# about: A plugin to demonstrate adding additional providers to discourse-chat-integration
# version: 0.1
# url: https://github.com/davidtaylorhq/discourse-chat-ifttt
# author: David Taylor

enabled_site_setting :chat_integration_ifttt_enabled

after_initialize do
  require_relative "../discourse-chat-integration/app/initializers/discourse_chat"

  # Register a module under DiscourseChat::Provider which ends in the word "Provider"
  module DiscourseChat::Provider::IftttProvider
        PROVIDER_NAME = "ifttt".freeze
        PROVIDER_ENABLED_SETTING = :chat_integration_ifttt_enabled
        CHANNEL_PARAMETERS = [
                          {key: "event", regex: '^\S+$'} # No whitespace
                         ]

        def self.trigger_notification(post, channel)
          event = channel.data['event']
          key = SiteSetting.chat_integration_ifttt_webhook_key

          # Build up a message (ifttt only accepts value1 value2 and value3 as keys)
          message = {
            value1: post.full_url,
            value2: post.topic.title,
            value3: post.excerpt(nil, text_entities: true, strip_links: true, remap_emoji: true)
          }

          # Send a POST request to the ifttt API
          http = Net::HTTP.new("maker.ifttt.com", 443)
          http.use_ssl = true
          uri = URI("https://maker.ifttt.com/trigger/#{event}/with/key/#{key}")
          req = Net::HTTP::Post.new(uri, 'Content-Type' =>'application/json')
          req.body = message.to_json
          response = http.request(req)

          # Add some error checking
          unless response.kind_of? Net::HTTPSuccess
            error_key = nil
            if response.body.include? 'invalid key'
              error_key = 'chat_integration.provider.ifttt.invalid_key'
            end
            raise ::DiscourseChat::ProviderError.new info: {error_key: error_key, message: message, response_body:response.body}
          end

        end
      
  end

end