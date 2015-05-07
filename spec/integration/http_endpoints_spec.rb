require 'spec_helper'

describe 'http endpoints', type: :feature, sauce: true do
  it 'should show the page' do
    visit '/simple_http'
    expect(page).to have_content('this is just some text')
  end

  it 'should have access to the store' do
    store._simple_http_tests << { name: 'hello' }
    visit '/simple_http/store'
    expect(page).to have_content('You had me at hello')
  end

  it 'should upload and store a file' do
    file = 'tmp/uploaded_file'
    FileUtils.rm(file) if File.exist?(file)
    visit '/upload'
    attach_file('file', __FILE__)
    find('#submit_file_upload').click
    expect(page).to have_content('successfully uploaded')
    expect(File.exist?(file)).to be(true)
    FileUtils.rm(file) if File.exist?(file)
  end
end
