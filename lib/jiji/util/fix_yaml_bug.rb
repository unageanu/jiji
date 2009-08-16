
require 'yaml'

# for yaml bug.
class String
  def is_binary_data? # [ruby-list:16014]
    return true if self.include?(0)
    check = self[0, 512]
    check.size < 10 * check.count("\x00-\x07\x0b\x0e-\x1a\x1c-\x1f")
  end
end