# encoding: utf-8
# rails runner db/Refinerysk.rb

module Refinery
  users = [
    {:username => 'Marek Laboš', :email => 'keraml@gmail.com'}
  ]

  users.each do |user|
    if User.find_by_email(user[:email]).nil?
      p = (Rails.env.production?) ? (0...32).map{ ('a'..'z').to_a[rand(26)] }.join : 'nbusr123'
      u = User.create(user.merge({:password => p, :password_confirmation => p}))
      u.add_role(:superuser)
      u.add_role(:refinery)
    end
  end

  ids = Refinerysk::Application::PAGES
  pages = {
    :home => {
			:title => { :sk => 'Úvod' }
    },
    :about => {
			:title => { :sk => 'O nás' }
    },
    :contact => {
      :title => { :sk => 'Kontakt' },
    },
    :contact_thank_you => {
      :title => { :sk => 'Ďakujeme' },
    }
  }

  pages.each do |i, p|
    id = "#{i}_page_id".upcase.to_sym
    page = Page.find_by_id(ids[id])
    attributes = {:deletable => false, :show_in_menu => true}
    attributes = attributes.merge(p[:attributes]) if p[:attributes]

    unless page
      attributes = attributes.merge({:title => p[:title][::I18n.locale].to_s})
      page = Page.create(attributes)
    end

    unless page.parts.find_by_title('Body')
      page.parts.create({
          :title => 'Body',
          :body => "",
          :position => 0
        })
    end

    unless page.parts.find_by_title('Side Body')
      page.parts.create({
          :title => 'Side Body',
          :body => "",
          :position => 1
        })
    end

    I18n.frontend_locales.each do |lang|
      ::I18n.locale = lang

      page_body_file_path = Rails.root.join("db/templates/#{i}_body_#{lang}.html")
      page_sidebar_file_path = Rails.root.join("db/templates/#{i}_sidebar_#{lang}.html")

      page.parts.find_by_title('Body').update_attributes(:body => File.exist?(page_body_file_path) ? IO.read(page_body_file_path) : "-t- #{i} body")
      page.parts.find_by_title('Side Body').update_attributes(:body => File.exist?(page_sidebar_file_path) ? IO.read(page_sidebar_file_path) : "")

      attributes = attributes.merge({:custom_slug => p[:custom_slug][lang].to_s}) if p[:custom_slug] and p[:custom_slug][lang]
      attributes = attributes.merge({:title => p[:title][lang].to_s})

      page.update_attributes(attributes)
    end if I18n.frontend_locales.any?

    page.save!
  end

#  contact_page = Page.find_by_id(ids[:CONTACT_PAGE_ID])
#  referencies_page = Page.find_by_id(ids[:REFERENCIES_PAGE_ID])
#  about_page = Page.find_by_id(ids[:ABOUT_PAGE_ID])
#
#  contact_page.move_to_right_of(referencies_page)
#  about_page.move_to_right_of(referencies_page)

end
