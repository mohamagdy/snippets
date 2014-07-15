def self.search(params)
  query = "#{params[:field] || 'name'}:#{params[:q]}"
  tire.search(load: params[:load]) do
    # Query
    query { string query, default_operator: 'AND' } if params[:q].present?

    # Query filters
    if params[:filter][:filter_value]
      filter :term, params[:filter][:filter_field] => params[:filter][:filter_value]
    else # If no value is passed then consider it as a missing (null valued) parameter
      filter :missing, field: params[:filter][:filter_field]
    end if params[:filter].present?

    # Query size
    size params[:size] || AppConfig.search_size

    # Sorting results by exact name
    sort { by :exact_name, 'asc' }

    # Facets
    facet('initials', global: true) do
      terms :starting_character, size: (params[:size] || AppConfig.search_size)

      if params[:filter][:filter_value]
        facet_filter :term, params[:filter][:filter_field] => params[:filter][:filter_value]
      else # If no value is passed then consider it as a missing (null valued) parameter
        facet_filter :missing, field: params[:filter][:filter_field]
      end if params[:filter].present?
    end
  end
end