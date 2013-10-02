# encoding: UTF-8
require 'rspec/core/rake_task'
require 'yard'

desc 'Default: run specs.'
task :default => :spec

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec) do |t|
end

YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = ['*.rb', '-', '*.md']
end
