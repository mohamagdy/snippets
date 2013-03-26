  # This method takes a url and returns either set of images and description of the url (meta info) or the html
  # code of the video to embed in the HTML 
  def fetch_url_meta(url)
    begin
      # Initializing Mechanize
      page = Mechanize.new.get(url)
      
      # Initializing OEmbed
      OEmbed::Providers.register_all
      oembed = OEmbed::Providers.find(url)
      resource = oembed.try(:get, url)
      
      # Grap the page description or title
      description = if resource
        resource.respond_to?(:description) ? resource.description : resource.title
      else
        page.at('head meta')['content']
      end 
      
      metadata = { description: description }
        
      if resource.try(:video?)
        # If video return the HTML code to embed in the page
        metadata.merge!({ html: resource.html, video: true })
      else
        images = page.image_urls.map(&:to_s) # Grap all the images in the link
        images << resource.thumbnail_url if resource.respond_to?(:thumbnail_url) # Grap the thumbnail using the provider
        
        metadata.merge!({ images: images.uniq, video: false })
      end
    rescue
      { error: true }
    end
  end 