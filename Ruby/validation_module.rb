module PreferredLocationValidations
  def self.included(base_class)
    base_class.class_eval do
      include ActiveModel::Validations
      validate :preferred_location_count
      
      # This method valdiates that the number of the preferred locations created for the user (logged in or not)
      # doesn't exceed the allowed count
      def preferred_location_count
        if self.preferred_locations_count == AppConfig.max_preferred_location_count
          self.errors[:base] << I18n.t('errors.messages.max_number_reached')
          false
        end
      end          
    end
  end
end