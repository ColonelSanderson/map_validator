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

`mandatory` determines whether a nil value should short-circuit the validation or not.
`vocabulary` is the vocabulary to match the value against
`true_value`/`false_value` are the boolean options (eg. `yes`/`no`)
