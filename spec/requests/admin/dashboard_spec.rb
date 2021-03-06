# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

describe "Admin::Dashboard", type: :request do
  describe "root path" do
    it "offers to setup an administrator account if there is none" do
      visit root_path
      expect(page).to have_content("Let's setup an administrator account first!")
    end

    context 'when logged in as an admin' do
      before do |example|
        login(admin, example)
      end

      it "offers to setup a site if the logged in user doesn't have any" do
        visit root_path
        expect(page).to have_content("Let's get started!")
        expect(page).to have_content("So you want to embed comments on a bunch of web pages.")
      end

      context 'user has sites' do
        before do
          FactoryGirl.create(:site1, :user => admin)
        end

        it "redirects to the sites page if the user is logged in, there are administrators and the current user has sites" do
          visit root_path
          expect(current_path).to eq(admin_sites_path)
        end
      end
    end
  end

  describe "setting up an initial administrator account" do
    it "creates the account, logs in the user and asks the user to setup a site" do
      visit root_path
      fill_in 'Email', :with => 'a@a.com'
      fill_in 'Password', :with => '123456'
      fill_in 'Confirm password', :with => '123456'
      click_button 'Create account & login'
      user = User.first
      expect(user.email).to eq('a@a.com')
      expect(user).to be_admin
      expect(page).to have_css("#debug .current_user", :text => user.id.to_s, visible: false)
      expect(page).to have_content("So you want to embed comments on a bunch of web pages")
    end

    it "refuses to create the account opon errors" do
      visit root_path
      click_button 'Create account & login'
      expect(page).to have_css("#error_explanation")
      expect(User.count).to eq(0)
    end
  end

  describe "setting up a site" do
    before :each do |example|
      login(admin, example)
      visit '/admin/dashboard/new_site'
    end
    
    it "works" do
      expect(page).to have_content("So you want to embed comments on a bunch of web pages")
      fill_in 'site[name]', :with => 'Foo'
      choose 'Manually approve all comments.'
      click_button 'Next step »'
      expect(page).to have_content("Your site \"Foo\" has been registered!")
      expect(Site.find_by_name('Foo')).not_to be_nil
    end
    
    it "refuses to create the site upon errors" do
      click_button 'Next step »'
      expect(page).to have_content("prohibited this site from being created")
      expect(page).to have_content("So you want to embed comments on a bunch of web pages")
    end
  end
end
