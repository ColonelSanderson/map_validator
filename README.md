### Validations functions and options
* is_not_nil
* is_not_empty
* is_integer
    * min_value
    * mandatory
* is_valid_date
    * mandatory
* is_in_vocab
    * mandatory
    * vocabulary
* is_boolean
    * mandatory
    * true_value
    * false_value
* row_id_exists
    * mandatory
    * type
    * id_field
* has_one_of    
    * field_list
* is_unique_within_column
    * mandatory

`mandatory` determines whether a nil value should short-circuit the validation or not.
`vocabulary` is the vocabulary to match the value against
`true_value`/`false_value` are the boolean options (eg. `yes`/`no`)
`type` refers to the the record type in Solr
`id_field` refers to the field to match on
`field_list` determines what fields to check, in addition to the currently parsing field.
