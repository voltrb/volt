if RUBY_PLATFORM == 'opal'
else
  require 'benchmark'
  require 'volt/server/html_parser/view_handler'

  describe Volt::ViewHandler do
    let(:handler) { Volt::ViewHandler.new('main/main/main') }

    it 'handles tags' do
      handler.comment('Yowza!')
      handler.start_tag('a', { href: 'yahoo.com' }, false)
      handler.text('Cool in 1996')
      handler.end_tag('a')

      expectation = '<!--Yowza!--><a href="yahoo.com">Cool in 1996</a>'
      expect(handler.html).to eq(expectation)
    end
  end

end
