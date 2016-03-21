# Simple model to handle validation
class Contact
  include ActiveModel::Validations
  attr_accessor :phone

  validates :phone, :phony_plausible => true, :presence => true
end