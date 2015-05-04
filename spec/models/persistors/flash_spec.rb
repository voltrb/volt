require 'spec_helper'

module Volt
  module Persistors
    describe Flash do
      let(:fake_parent) { double('Parent', delete: true) }
      let(:fake_passed_model) { double }

      let(:fake_model) do
        double(
          'Model',
          size: 1,
          parent: fake_parent,
          path: '12',
          delete: true
        )
      end

      describe '#added' do
        it 'returns nil' do
          flash = described_class.new double

          expect(flash.added(double, 0)).to be_nil
        end
      end

      describe '#clear_model' do
        it 'sends #delete to @model' do
          described_class.new(fake_model).clear_model fake_passed_model

          expect(fake_model).to have_received(:delete).with(fake_passed_model)
        end

        it 'with a size of zero, parent receives #delete' do
          collection_name = fake_model.path[-1]
          allow(fake_model).to receive(:size).and_return 0

          described_class.new(fake_model).clear_model fake_passed_model

          expect(fake_parent).to have_received(:delete).with(collection_name)
        end
      end
    end
  end
end
