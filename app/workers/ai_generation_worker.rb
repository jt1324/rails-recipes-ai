# app/workers/ai_generation_worker.rb
class AiGenerationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5

  sidekiq_retry_in do |count|
    15 * (count + 1) # 15s, 30s, 45s, 60s, 75s
  end

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)

    # Call your AI generation method
    recipe.set_content  # or recipe.generate_ai_content!
    recipe.save!

  rescue Faraday::TooManyRequestsError => e
    Rails.logger.error "OpenAI rate limit for recipe #{recipe_id}"
    # Sidekiq will automatically retry with backoff
    raise e
  rescue StandardError => e
    Rails.logger.error "Error generating recipe #{recipe_id}: #{e.message}"
    raise e
  end
end
