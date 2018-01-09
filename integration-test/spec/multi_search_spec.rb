#!/usr/bin/env ruby

require './spec/spec_helper'

describe 'My Feature' do
  before do
    @user = admin_session.create_test_user
    page.log_in_as(@user)
    page.create_document_set_from_csv('files/multi-search.csv')
    page.create_custom_view(name: 'multi-search', url: 'http://overview-multi-search')

    # Wait for iframe to appear. (Its contents aren't loaded yet.)
    page.assert_selector('iframe#view-app-iframe', wait: WAIT_LOAD)

    # Wait for document list to load, so we can wait for it to _change_ later
    page.assert_selector('h3', text: 'First Document', wait: WAIT_LOAD)
  end

  after do
    admin_session.destroy_test_user(@user)
  end

  it 'should search' do
    page.within_frame('view-app-iframe') do
      page.fill_in('Search for', with: 'number t*', wait: WAIT_LOAD) # wait for JS to build form
      page.click_button('Search')
      page.assert_selector('h5', text: 'number t*', wait: WAIT_FAST) # wait for search to appear in iframe
    end

    # This is _filtering_: wait for a document to disappear, then we know it's done
    page.assert_no_selector('h3', text: 'First Document', wait: WAIT_LOAD) # wait for old list -> loading...
    page.assert_no_selector('h3', text: 'Finding Documents', wait: WAIT_LOAD) # wait for loading... -> new list

    page.assert_selector('h3', text: 'Third Document', wait: WAIT_FAST) # wait for new list to render
    page.assert_no_selector('h3', text: 'First Document')
    assert_equal('number t*', page.find_field('Search').value)
  end

  it 'should persist searches across page loads' do
    page.within_frame('view-app-iframe') do
      page.fill_in('Search for', with: 'number t*', wait: WAIT_LOAD) # wait for JS to build form
      page.click_button('Search')
      sleep(1) # make sure the save completes
    end

    page.refresh

    page.within_frame('view-app-iframe', wait: WAIT_LOAD) do # Wait for page to load
      page.assert_selector('h5', text: 'number t*', wait: WAIT_LOAD) # Wait for iframe to load
    end
  end
end
