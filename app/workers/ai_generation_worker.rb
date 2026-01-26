# app/workers/ai_generation_worker.rb
class AiGenerationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 10  # More retries

  sidekiq_retry_in do |count|
    60 * (count + 1)  # Wait 60s, 120s, 180s, 240s, etc.
  end

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)

    # Add a small delay before even starting
    sleep(2)

    recipe.generate_ai_content!

  rescue Faraday::TooManyRequestsError => e
    Rails.logger.error "OpenAI rate limit for recipe #{recipe_id}, will retry in #{60 * (retry_count + 1)} seconds"
    raise e
  rescue StandardError => e
    Rails.logger.error "Error: #{e.message}"
    raise e
  end
end
