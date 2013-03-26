# This class was created as the users can save their preferred locations either when they're logged in
# or when they're not. This class saves the user's preferred location but without persisting it in the database
class NonPersistedPreferredLocation < OpenStruct
  include PreferredLocationValidations # Validations
  
  # Overriding the save method to return true if the object is valide and the "errors" attribute is not set
  def save
    self.errors.blank? && self.valid? ? true : false  
  end
end

# Usage in the preferred locations controller

# POST /preferred_locations
# POST /preferred_locations.json
def create
	# Either presist in the database or in a cookie according to either the user is logged in or not
	initialize_preferred_location

	respond_to do |format|
	  if @preferred_location.save
	    format.html { redirect_to @preferred_location, notice: 'Preferred location was successfully created.' }
	    format.json { render json: @preferred_location, status: 200 }
	  else
	    format.html { render action: 'new' }
	    format.json { render json: @preferred_location.errors, status: 406 }
	  end
	end
end
  
# This method saves the preferred location. In case of a logged in user, the preferred location will be saved
# in the database else it will be saved in the browser's cookies
def initialize_preferred_location
	begin
	  geography = Geography.find(params[:preferred_location][:geography_id]) # Finding the geography before saving it
	  
	  if user_signed_in? # Registered and logged in user
	    @preferred_location = current_user.preferred_locations.new(params[:preferred_location]) # Save in the database 
	  else # Non logged in user
	    geography_ids = preferred_locations_ids
	    @preferred_location = NonPersistedPreferredLocation.new(id: geography.id, geography_name: geography.name, 
	                                                            preferred_locations_count: geography_ids.count)
	                                                            
	    cookies[:geography_ids] = (geography_ids << geography.id).to_json if @preferred_location.valid? 
	  end
	rescue
	  @preferred_location = NonPersistedPreferredLocation.new(errors: t('errors.messages.geography_not_found'))
	end
end

def preferred_locations_ids
	user_signed_in? ? current_user.preferred_locations.map(&:geography_id) : JSON.parse(cookies[:geography_ids] || '[]')
end
