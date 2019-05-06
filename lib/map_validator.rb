require_relative 'notifications'
require_relative 'validator_functions'
require_relative 'vocabularies'
require 'csv'

class MapValidator
  attr_reader :notifications
  def initialize
    @notifications = Notifications.new
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
          @notifications.add_notification(:WARNING,
                                          "There was no validation rule found for column #{colName}.",
                                          '')
        end
      end
      firstrun = false
    end
  end
end

validations = {
  'Disposal Class': Proc.new(&method("is_not_empty")),
  'Title': Proc.new(&method("is_not_empty")),
    # Description: ,
    # "Agency Control number":,
  'Sequence Number': Proc.new(&method("is_not_empty")),
  # 'Attachment Related to Sequence Number':
  # 'Attachment Notes':
  'Access Category': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:accessCategories]), col)},
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
  'Format - Physical': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:formatPhysical]), col)},
  'Contained with': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:containedWith]), col)},
  'Box Number': proc do |notifications, meta, col|
    is_not_nil(notifications, meta, col) &&
      is_integer(notifications, meta.merge(minValue: 0), col)
  end,
    # Remarks
    # "Series ID"
    # "Responsible Agency"
    # "Creating Agency"
  'Sensititvity Label': proc {|notifications, meta, col| is_in_vocab(notifications, meta.merge(vocabulary: getVocabularies[:sensitivityLabels]), col)}
}

csv_validator = MapValidator.new
csv_validator.run_validations("/home/seana/transferlist.csv", validations)
csv_validator.notifications.notification_list.each {|notification| puts "[#{notification.type}](#{notification.source}): #{notification.message}" }