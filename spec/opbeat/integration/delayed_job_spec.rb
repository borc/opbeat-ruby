require 'spec_helper'

begin
  require 'delayed_job'
rescue LoadError
  puts "Skipping delayed_job specs"
end

if defined?(Delayed)
  # so nasty
  load File.join(
    Gem::Specification.find_by_name("delayed_job").gem_dir,
    "spec", "delayed", "backend", "test.rb"
  )
  Delayed::Worker.backend = Delayed::Backend::Test::Job

  describe Delayed::Plugins::Opbeat do
    class MyJob
      def blow_up e
        raise e
      end
    end

    let(:config) { Opbeat::Configuration.new }
    before { Opbeat.start! config }
    after  { Opbeat.stop! }

    it "reports exceptions to Opbeat" do
      exception = Exception.new('BOOM')

      MyJob.new.delay.blow_up exception

      expect(Delayed::Worker.new.work_off).to eq [0, 1]
      expect(WebMock).to have_requested(:post, %r{/errors/$}).with({
        body: /{"message":"Exception: BOOM"/
      })
    end
  end
end
