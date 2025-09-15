# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Run security audit'
task :audit do
  system('bundle-audit check --update')
end

task default: %i[spec rubocop audit]
