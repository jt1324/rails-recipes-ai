class RecipeContentJob < ApplicationJob
  queue_as :default

  # def perform(recipe)
  #   client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"))
  #   chatgpt_response = client.chat(parameters: {
  #     model: "gpt-4o-mini",
  #     messages: [{ role: "user", content: "Give me a simple recipe for #{recipe.name} with the ingredients #{recipe.ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
  #   })
  #   new_content = chatgpt_response["choices"][0]["message"]["content"]

  #   recipe.update!(content: new_content)

  # end
end
