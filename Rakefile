require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "cromwell"
    gem.summary = %Q{Lord Protector of your scripts}
    gem.description = %Q{A very simple wrapper over Signal#trap method that allows you to easily protect your scripts from being killed while they are doing something that should not be interrupted (e.g. interacting with some non-transactional service) or is too costly to restart (e.g. long computations). }
    gem.email = "szeryf@negativeiq.pl"
    gem.homepage = "http://github.com/szeryf/cromwell"
    gem.authors = ["Przemyslaw Kowalczyk"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.rcov_opts << "-x /gems/"
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cromwell #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'metric_fu'
rescue LoadError
  puts "metric_fu (or a dependency) not available. If you want to run metrics, install it with: gem install metric_fu"
end

MetricFu::Configuration.run do |config|
  #define which metrics you want to use
  config.metrics  = [:churn, :saikuro, :flog, :flay, :reek, :roodi, :rcov]
  config.graphs   = []
  config.flay     = { :dirs_to_flay  => ['lib']  }
  config.flog     = { :dirs_to_flog  => ['lib']  }
  config.reek     = { :dirs_to_reek  => ['lib']  }
  config.roodi    = { :dirs_to_roodi => ['lib'] }
  config.saikuro  = { :output_directory => 'scratch_directory/saikuro',
                      :input_directory => ['lib'],
                      :cyclo => "",
                      :filter_cyclo => "0",
                      :warn_cyclo => "5",
                      :error_cyclo => "7",
                      :formater => "text"} #this needs to be set to "text"
  config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
  config.rcov     = { :test_files => ['test/**/test_*.rb'],
                      :rcov_opts => ["--sort coverage",
                                     "--no-html",
                                     "--text-coverage",
                                     "--no-color",
                                     "--exclude /gems/,/Library/,spec"]}
end

# fix for failing on NaN
module MetricFu
  class Generator
    def round_to_tenths(decimal)
      decimal=0.0 if decimal.to_s.eql?('NaN')
      (decimal.to_i * 10).round / 10.0
    end
  end
end