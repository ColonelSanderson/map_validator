require 'roo'

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

  def run_validations(excelFileOrPath, validations)
    xlsx = Roo::Excelx.new(excelFileOrPath)

    headers = xlsx.sheet(0).first
    row_index = 0
    xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
      row.first(headers.count).each_with_index do |col, col_index|
        col_value = !col.nil? ? col.value : nil
        if col_index > headers.count()
          next
        end
        col_name = headers[col_index]
        field_metadata = { xlsx: xlsx, headers: headers, row_fields: row, col: col_name, col_index: col_index + 1, row_index: row_index }
        has_validation_rule = !validations[col_name.intern].nil?
        if has_validation_rule
          validations[col_name.intern].call(@notifications, field_metadata, col_value)
        elsif row_index == 0
          @notifications.add_notification(:DEBUG,
                                          "There was no validation rule found for column #{col_name}.",
                                          '')
        end
      end
      row_index += 1
    end
  end

  def enable_debug
    @notifications.enable_debug
  end

  def sample_validations
    {
      # 'Disposal Class': Proc.new(&method('is_not_empty')),
      'Title': Proc.new(&method('is_not_empty')),
        # Description: ,
        # "Agency Control number":,
      'Sequence Number': proc do |notifications, meta, col|
          has_one_of(notifications, meta.merge(field_list: ['Sequence Number', 'Attachment Related to Sequence Number']), col)
          is_unique_within_column(notifications, meta, col)
        end,
      # 'Attachment Related to Sequence Number':
      # 'Attachment Notes':
      'Restricted Access Period': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:accessCategories]), col)},
      'Publish Metadata?': proc do |notifications, meta, col|
          is_boolean(notifications, meta.merge(mandatory: true, true_value: 'Y', false_value: 'N'), col)
        end,
      'Start Date': proc {|notifications, meta, col| is_valid_date(notifications, meta, col)},
      'Start Date Qualifier': proc do |notifications, meta, col|
          is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:dateQualifierVocabularies]), col)
        end,
      'End Date': proc {|notifications, meta, col| is_valid_date(notifications, meta, col)},
      'End Date Qualifier': proc do |notifications, meta, col|
          is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:dateQualifierVocabularies]), col)
        end,
      'Representation Type': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:representationType]), col)},
      'Format': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:format]), col)},
      'Contained within': proc do |notifications, meta, col|
        is_in_vocab(notifications, meta.merge(mandatory: true, vocabulary: getVocabularies[:containedWithin]), col)
        end,
      'Box Number': proc do |notifications, meta, col|
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
# csv_validator.run_validations('path/to/file.xlsx', csv_validator.sample_validations)
# csv_validator.notifications.notification_list.each {|notification| puts "[#{notification.type}](#{notification.source}): #{notification.message}" }
