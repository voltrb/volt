if RUBY_PLATFORM != 'opal'
  describe Volt::VoltLogger do
    let(:args)        { [5, :arg2] }
    let(:class_name)  { 'ClassName' }
    let(:method_name) { 'method_name' }
    let(:run_time)    { 50 }

    let(:logger) { Volt::VoltLogger.new }

    let(:logger_with_opts) do
      Volt::VoltLogger.new({
        args: args,
        class_name: class_name,
        method_name: method_name,
        run_time: run_time
      })
    end

    it 'should log only severity and message wrapped in line breaks' do
      expect(STDOUT).to receive(:write).with("\n\n[INFO] message\n")
      logger.log(Logger::INFO, "message")
    end

    it 'should convert an array of arguments into a string' do
      expect(logger_with_opts.args).to eq([5, :arg2])
    end

    describe 'when STDOUT is a TTY' do
      before { allow(STDOUT).to receive(:tty?).and_return(true) }
      
      it 'should return a blue class name' do
        expect(logger_with_opts.class_name).to eq("\e[1;34m#{class_name}\e[0;37m")
      end

      it 'should return a green method name' do
        expect(logger_with_opts.method_name).to eq("\e[0;32m#{method_name}\e[0;37m")
      end

      it 'should return a green run time in milliseconds' do
        expect(logger_with_opts.run_time).to eq("\e[0;32m#{run_time}ms\e[0;37m")
      end
    end

    describe 'when STDOUT is not a TTY' do
      before { allow(STDOUT).to receive(:tty?).and_return(false) }

      it 'should not add any terminal color codes' do
        expect(logger_with_opts.class_name).to eq(class_name)
      end
    end
  end
end
