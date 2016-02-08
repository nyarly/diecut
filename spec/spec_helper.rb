require 'cadre/rspec3'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "example_results.txt"
  config.add_formatter(Cadre::RSpec3::NotifyOnCompleteFormatter)
  config.add_formatter(Cadre::RSpec3::QuickfixFormatter)

  config.mock_with(:rspec) do |mock|
    mock.verify_partial_doubles = true
    mock.verify_doubled_constant_names = true
  end

  config.before(:suite) do
    Diecut.issue_handler = Diecut::ErrorHandling::Silent.new
  end
end
