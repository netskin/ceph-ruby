require 'bundler/gem_tasks'

Dir.glob('tasks/**/*.rake').each(&method(:import))

task test: [:rubocop_test, :spec]

task dev_test: [:rubocop_dev, :spec]
