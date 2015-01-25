# encoding: utf-8
require 'spec_helper'
require 'extra_core/string_transformation_test_cases'
require 'volt/extra_core/string'

describe '#camelize' do
  CamelToUnderscore.each do |camel, underscore|
    it 'camelizes' do
      expect(underscore.camelize).to eq(camel)
    end
  end

  it 'camelizes lower' do
    expect('capital_city'.camelize(:lower)).to eq('capitalCity')
  end

  it 'camelizes upper' do
    expect('capital_city'.camelize(:upper)).to eq('CapitalCity')
  end

  it 'camelizes upper default' do
    expect('capital_city'.camelize).to eq('CapitalCity')
  end

  UnderscoreToLowerCamel.each do |underscored, lower_camel|
    it 'camelizes lower' do
      expect(underscored.camelize(:lower)).to eq(lower_camel)
    end
  end

  UnderscoresToDashes.each do |underscored, dasherized|
    it 'dasherizes' do
      expect(underscored.dasherize).to eq(dasherized)
    end
  end

  CamelToUnderscore.each do |camel, underscore|
    it 'underscores' do
      expect(camel.underscore).to eq(underscore)
    end
  end

  it 'underscores acronyms' do
    expect('HTMLTidy'.underscore).to eq('html_tidy')
    expect('HTMLTidyGenerator'.underscore).to eq('html_tidy_generator')
  end
end
