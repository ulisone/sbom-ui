require "net/http"
require "uri"
require "json"

class WebhookService
  def self.send_notification(url:, type:, title:, message:, notification_type:, data: {})
    new(url, type, title, message, notification_type, data).send_notification
  end

  def initialize(url, type, title, message, notification_type, data)
    @url = url
    @type = type
    @title = title
    @message = message
    @notification_type = notification_type
    @data = data
  end

  def send_notification
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("Webhook failed with status #{response.code}: #{response.body}")
    end

    response
  rescue StandardError => e
    Rails.logger.error("Webhook error: #{e.message}")
    nil
  end

  private

  attr_reader :url, :type, :title, :message, :notification_type, :data

  def payload
    case type
    when "slack"
      slack_payload
    when "discord"
      discord_payload
    else
      generic_payload
    end
  end

  def slack_payload
    {
      text: title,
      attachments: [
        {
          color: severity_color,
          blocks: [
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: "*#{title}*\n#{message}"
              }
            },
            {
              type: "context",
              elements: [
                {
                  type: "mrkdwn",
                  text: "SBOM Dashboard | #{Time.current.strftime('%Y-%m-%d %H:%M')}"
                }
              ]
            }
          ]
        }
      ]
    }
  end

  def discord_payload
    {
      content: nil,
      embeds: [
        {
          title: title,
          description: message,
          color: discord_color,
          timestamp: Time.current.iso8601,
          footer: {
            text: "SBOM Dashboard"
          }
        }
      ]
    }
  end

  def generic_payload
    {
      event: notification_type,
      title: title,
      message: message,
      timestamp: Time.current.iso8601,
      data: data
    }
  end

  def severity_color
    case notification_type
    when Notification::CRITICAL_VULNERABILITY
      "danger"
    when Notification::HIGH_VULNERABILITY
      "warning"
    when Notification::SCAN_COMPLETE
      "good"
    else
      "#3B82F6"
    end
  end

  def discord_color
    case notification_type
    when Notification::CRITICAL_VULNERABILITY
      15158332  # Red
    when Notification::HIGH_VULNERABILITY
      15105570  # Orange
    when Notification::SCAN_COMPLETE
      3066993   # Green
    else
      3447003   # Blue
    end
  end
end
