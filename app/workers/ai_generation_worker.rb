# app/workers/ai_generation_worker.rb
class AiGenerationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5

  sidekiq_retry_in do |count|
    20 * (count + 1) # 20s, 40s, 60s, 80s, 100s
  end

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)
    recipe.generate_ai_content!

  rescue Faraday::TooManyRequestsError => e
    Rails.logger.error "OpenAI rate limit for recipe #{recipe_id}, will retry"
    raise e # Sidekiq will retry with backoff
  end
end
