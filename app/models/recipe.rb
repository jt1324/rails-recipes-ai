require "open-uri"

class Recipe < ApplicationRecord
  has_one_attached :photo
  # after_save if: -> { saved_change_to_name? || saved_change_to_ingredients? } do
  #   set_content
  #   set_photo
  # end


  #

  def generate_ai_content!
    # Your OpenAI API call here
    generated_content = call_openai_api

    # Save it to the database
    update_column(:content, generated_content)
  end


  private

  def set_content
    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"))
    chatgpt_response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: "Give me a simple recipe for #{name} with the ingredients #{ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
    })
    new_content = chatgpt_response["choices"][0]["message"]["content"]

    update(content: new_content)
    return new_content
    # RecipeContentJob.perform_later(self)
  end



  def set_photo
    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"))

    # Make sure `name` is present
    if name.blank?
      Rails.logger.error "set_photo: name is blank, skipping image generation"
      return
    end

    begin
      response = client.images.generate(
        parameters: {
          model: "gpt-image-1",
          prompt: "A realistic recipe image of #{name} without any text",
          size: "1024x1024",
          n: 1
        }
      )
    # Prefer Faraday::ClientError (covers 4xx/5xx from Faraday)
    rescue defined?(Faraday) && Faraday.const_defined?(:ClientError) ? Faraday::ClientError : StandardError => e
      # try to surface the API JSON error body for debugging (if available)
      body = e.respond_to?(:response) && e.response && e.response[:body]
      status = e.respond_to?(:response) && e.response && e.response[:status]
      headers = e.respond_to?(:response) && e.response && e.response[:headers]
      Rails.logger.error "OpenAI images error status: #{status.inspect}"
      Rails.logger.error "OpenAI images response headers: #{headers.inspect}"
      Rails.logger.error "OpenAI images response body: #{body || e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "Unexpected error when generating image: #{e.class} - #{e.message}"
      raise
    end

    data = response.dig("data") || response.dig(:data)
    unless data && data[0]
      Rails.logger.error "Unexpected OpenAI images response: #{response.inspect}"
      return
    end

    image_item = data[0]
    if image_item["b64_json"] || image_item[:b64_json]
      b64 = image_item["b64_json"] || image_item[:b64_json]
      decoded = Base64.decode64(b64)
      io = StringIO.new(decoded)
      filename = "ai_generated_image.png"
      content_type = "image/png"

      photo.purge if photo.attached?
      photo.attach(io: io, filename: filename, content_type: content_type)
    elsif image_item["url"] || image_item[:url]
      url = image_item["url"] || image_item[:url]
      file = URI.parse(url).open
      photo.purge if photo.attached?
      photo.attach(io: file, filename: "ai_generated_image.png", content_type: "image/png")
    else
      Rails.logger.error "No image content in response: #{image_item.inspect}"
    end

    photo
  end



    # response = client.images.generate(parameters: {
    #   prompt: "A recipe image of #{name}", size: "1024x1024"
    # })

    # url = response["data"][0]["url"]
    # file =  URI.parse(url).open

    # photo.purge if photo.attached?
    # photo.attach(io: file, filename: "ai_generated_image.png", content_type: "image/png")
    # return photo
  # end

end
