# config/initializers/sidekiq.rb

if Rails.env.production?
  redis_url = ENV['REDIS_URL'] || ENV['REDIS_TLS_URL']

  redis_config = {
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }

  Sidekiq.configure_server do |config|
    config.redis = redis_config
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end
