# encoding: utf-8
# rails runner db/progressbar.rb

module Refinery

  module PbImport

    def self.import_settings

      settings = {
        :site_email => 'info@refinery.sk',
        :site_phone => '',
        :site_url => 'https://www.refinery.sk',
        :site_twitter => 'refinerysk',
        :site_twitter_link => 'https://twitter.com/refinerysk',
        :site_github_link => 'https://github.com/keram/refinerysk',
        :site_bank_account => '' ,
        :site_bank_iban => '' ,
        :site_bank_swift => '' ,
        :site_bitcoin => ''
      }

      settings.each {|k, v|
        Refinery::Setting.set(k, v.to_s)
        puts "#{k} : #{v}"
      }
      
    end

    def self.import_users

      users = [
        {:username => 'admin', :email => 'info@refinery.sk'}
      ]

      users.each do |user|
        u = User.find_by_email(user[:email])
        unless u
          p = (Rails.env.production?) ? (0...32).map{ ('a'..'z').to_a[rand(26)] }.join : 'nbusr123'
          u = User.create(user.merge({:password => p, :password_confirmation => p}))
          puts "User \"#{user[:username]}\" with email \"#{user[:email]}\" was created."
        end

        u.add_role(:superuser)
        u.add_role(:refinery)

        u.add_role(:member)
        u.add_role(:active_member)
        u.add_role(:moderator)

      end

      # one test user
      if Rails.env.development? and 1 == 2
        test_users = [
          {:username => 'jurko', :email => 'jurko@progressbar.sk'}
        ]

        test_users.each do |user|
          u = User.find_by_email(user[:email])
          unless u
            p = (Rails.env.production?) ? (0...32).map{ ('a'..'z').to_a[rand(26)] }.join : 'jurko'
            u = User.create(user.merge({:password => p, :password_confirmation => p}))
            puts "User \"#{user[:username]}\" with email \"#{user[:email]}\" was created."
          end

          u.add_role(:refinery)
        end
      end

    end

    def self.find_page_by_id_or_title (id, title)
      page = Page.find_by_id(id)
      current_locale = ::I18n.locale

      I18n.frontend_locales.each do |lang|
        ::I18n.locale = lang
        page = Page.find_by_title(title[lang]) unless page
      end

      ::I18n.locale = current_locale

      page
    end

    def self.import_pages
      ids = Refinerysk::Application::PAGES

      pages = {
        :home => {
          :title => { :sk => 'Úvod', :en => 'Home'},
          :menu_position => 10
        },
        :blog => {
          :title => { :sk => 'Blog', :en => 'Blog'},
          :attributes => {:deletable => false, :show_in_menu => true},
          :menu_position => 20
        },
        :gallery => {
          :title => { :sk => 'Galéria', :en => 'Gallery'},
          :attributes => {:deletable => false, :show_in_menu => false},
          :menu_position => 30
        },        
        :presentations => {
          :title => { :sk => 'Prezentácie a Návody', :en => 'Presentations' },
          :attributes => {:deletable => false, :show_in_menu => true},
          :menu_position => 40
        },
        :contact => {
          :title => { :sk => 'Kontakt', :en => 'Contact'},
          :menu_position => 50
        },
        :contact_thank_you => {
          :title => { :sk => 'Ďakujeme', :en => 'Thank You'},
          :attributes => {:deletable => false, :show_in_menu => false}
        },
        :about => {
          :title => { :sk => 'O nás', :en => 'About Us'},
          :attributes => {:deletable => false, :show_in_menu => false}
        },
        :colophon => {
          :title => { :sk => 'Tiráž', :en => 'Colophon'},
          :attributes => {:deletable => false, :show_in_menu => false}
        }
      }

      pages.each do |psym, p|
        id = "#{psym}_page_id".upcase.to_sym
        page = find_page_by_id_or_title(ids[id], p[:title])

        attributes = {:deletable => false, :show_in_menu => true}
        attributes = attributes.merge(p[:attributes]) if p[:attributes]

        page_created = false
        unless page
          attributes = attributes.merge({:title => p[:title][::I18n.locale].to_s})
          page = Page.create(attributes)
          page.save!
          page_created = true
        end

        Pages.default_parts.each_with_index do |part_title, i|
          part = page.parts.find_by_title(part_title)
          unless part
            page.parts.create({
                :title => part_title,
                :body => "",
                :position => i
              })
          else
            part.update_attributes(:position => i)
          end
        end

        I18n.frontend_locales.each do |lang|
          ::I18n.locale = lang

          Pages.default_parts.each do |part_title|
            file_part_name = part_title.downcase.gsub(/ /, '_')
            part_file_path = Rails.root.join("db/templates/#{psym}_#{file_part_name}_#{lang}.html")
            part = page.parts.find_by_title(part_title)
            part.update_attributes(:body => IO.read(part_file_path)) if File.exist?(part_file_path)
            # puts part_file_path # debug
          end

          attributes = attributes.merge({:custom_slug => p[:custom_slug][lang].to_s}) if p[:custom_slug] and p[:custom_slug][lang]
          attributes = attributes.merge({:title => p[:title][lang].to_s})
          page.update_attributes(attributes)
        end if I18n.frontend_locales.any?

        puts "Page \"#{page.title}\" (#{page.id}) #{page_created ? 'created' : 'updated'}."
      end


      tmp_arr = []
      menu_pages = []

      pages.each do |s, p|
        tmp_arr[p[:menu_position]] = Page.find_by_title(p[:title][::I18n.locale]) if p[:menu_position]
      end

      tmp_arr.compact.each do |p|
        menu_pages << p
      end

      menu_pages.each_with_index do |p, i|
        if i > 0
          p.move_to_right_of(menu_pages[i - 1])
        end
      end
    end

    def self.import_blog_posts
      post = {
        :title => 'test title',
        :body => 'test body',
        :user_id => 1,
        :published_at => Time.now
      }

      p = ::Refinery::Blog::Post.create({
        :title => post[:title],
        :body => post[:body],
        :draft => false,
        :user_id => post[:user_id],
        :published_at => post[:published_at]
      })

    end

  end

  puts 'import/update settings'
  PbImport.import_settings
  puts 'import/update users'
  PbImport.import_users
  puts 'import/update pages'
  PbImport.import_pages
#  puts 'import/update blog posts'
#  PbImport.import_blog_posts
end
