class AiGenerationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, queue: :default

  sidekiq_retry_in do |count|
    10 * (count + 1) # Retry after 10s, 20s, 30s, 40s, 50s
  end

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)

    # Your AI generation logic here
    # Example:
    recipe.generate_ai_content!
    recipe.update(status: 'completed')

  rescue Faraday::TooManyRequestsError => e
    Rails.logger.error "OpenAI rate limit hit for recipe #{recipe_id}"
    recipe.update(status: 'rate_limited')
    raise e # Let Sidekiq retry
  rescue StandardError => e
    Rails.logger.error "Error generating content for recipe #{recipe_id}: #{e.message}"
    recipe.update(status: 'failed')
    raise e
  end
end
