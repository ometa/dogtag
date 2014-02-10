class CSVGenerator
  class << self

    def to_csv(model, records, options = {})
      CSV.generate(options) do |csv|
        csv << model.column_names
        registrations.each do |registration|
          csv << registration.attributes.values_at(*column_names)
        end
      end
    end

  end
end
