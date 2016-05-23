require 'rubocop/rake_task'

desc 'Rub RoboCop on the lib and spec directory'
RuboCop::RakeTask.new(:rubocop_dev) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
  task.fail_on_error = false
end

RuboCop::RakeTask.new(:rubocop_test) do |task|
  task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
  task.formatters = ['files']
  task.fail_on_error = true
end
