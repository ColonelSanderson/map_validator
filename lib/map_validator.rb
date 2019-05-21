require 'csv'

require_relative 'map_validator/notifications'
require_relative 'map_validator/validator_functions'
require_relative 'map_validator/vocabularies'
require_relative '../config/default_config'

class MapValidator
  include MapValidator::ValidatorFunctions

  attr_reader :notifications
  def initialize(app_config = get_app_config)
    @notifications = Notifications.new
    @app_config = app_config
  end

  def run_validations(csvString, validations)
    table = CSV.read(csvString, headers: true)
    firstrun = true
    table.by_row.each_with_index do |row, rowIndex|
      row.each do |colName, col|
        field_metadata = { col: colName, row: rowIndex }
        has_validation_rule = !validations[colName.intern].nil?
        if has_validation_rule
          validations[colName.intern].call(@notifications, field_metadata, col)
        elsif firstrun
          @notifications.add_notification(:DEBUG,
                                          "There was no validation rule found for column #{colName}.",
                                          '')
        end
      end
      firstrun = false
    end
  end


  def enable_debug
    @notifications.enable_debug
  end

  def sample_validations
    {
      'Disposal Class': Proc.new(&method("is_not_empty")),
      'Title': Proc.new(&method("is_not_empty")),
        # Description: ,
        # "Agency Control number":,
      'Sequence Number': Proc.new(&method("is_not_empty")),
      # 'Attachment Related to Sequence Number':
      # 'Attachment Notes':
      'Restricted Access Period': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:accessCategories]), col)},
      'Publish Metadata?': proc do |notifications, meta, col|
        is_not_empty(notifications, meta, col) &&
          is_boolean(notifications, meta.merge(true_value: 'Yes', false_value: 'No'), col)
      end,
      'Start Date': proc {|notifications, meta, col| is_valid_date(notifications, meta.merge(mandatory: true), col)},
      'Start Date Qualifier': proc do |notifications, meta, col|
        is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:dateQualifierVocabularies]), col)
      end,
      'End Date': proc {|notifications, meta, col| is_valid_date(notifications, meta.merge(mandatory: true), col)},
      'End Date Qualifier': proc do |notifications, meta, col|
        is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:dateQualifierVocabularies]), col)
      end,
      'Representation Type': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:representationType]), col)},
      'Format': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:format]), col)},
      'Contained with': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:containedWith]), col)},
      'Box Number': proc do |notifications, meta, col|
        is_not_nil(notifications, meta, col) &&
          is_integer(notifications, meta.merge(minValue: 0), col)
      end,
        # Remarks
      'Series ID': proc {|notifications, meta, col| row_id_exists(notifications, meta.merge(type_name: 'primary_type', type: 'resource', id_field: 'identifier'), col)},
        # "Responsible Agency"
      'Creating Agency': proc {|notifications, meta, col| row_id_exists(notifications, meta.merge(type_name: 'types', type: 'agent', id_field: 'title'), col)},
      'Sensititvity Label': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:sensitivityLabels]), col)}
    }
  end
end

# csv_validator = MapValidator.new
# csv_validator.run_validations("/home/seana/transferlist.csv", csv_validator.sample_validations)
# csv_validator.notifications.notification_list.each {|notification| puts "[#{notification.type}](#{notification.source}): #{notification.message}" }
