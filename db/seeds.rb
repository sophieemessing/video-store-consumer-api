customer_data = JSON.parse(File.read('db/seeds/customers.json'))

customer_data.each do |customer|
  Customer.create!(customer)
end

JSON.parse(File.read('db/seeds/videos.json')).each do |video_data|
  sleep(0.1)                    # Sleep to avoid hammering the API.

  videos = VideoWrapper.search(video_data["title"])
  ap "#{video_data['title']} Added to the library!"
  videos.first.inventory = video_data['inventory']
  videos.first.save unless videos.empty?
end
