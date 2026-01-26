class AiGenerationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 15

  sidekiq_retry_in do |count|
    180 * (count + 1)  # 3min, 6min, 9min, 12min...
  end

  def perform(recipe_id)
    sleep(30)  # Wait before starting

    recipe = Recipe.find(recipe_id)

    Rails.logger.info "Starting AI generation for recipe #{recipe_id}"

    recipe.generate_ai_content!
    recipe.update(status: 'completed')

    Rails.logger.info "✅ Successfully generated recipe #{recipe_id}"

  rescue Faraday::TooManyRequestsError => e
    recipe.update(status: 'rate_limited') if recipe
    Rails.logger.error "⏸️ Rate limited for recipe #{recipe_id}"
    raise e

  rescue StandardError => e
    recipe.update(status: 'failed') if recipe
    Rails.logger.error "❌ Failed recipe #{recipe_id}: #{e.message}"
    raise e
  end
end
