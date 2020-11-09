require 'mechanize'

module Signaly
  # interaction with signaly.cz
  # (through the regular web interface intended for humans)
  class Client

    def initialize(config)
      @config = config
      @agent = Mechanize.new

      @dbg_print_pages = config.debug_output || false # print raw html of all request results?

      @checked_page = @config.url || 'https://www.signaly.cz/'
    end

    # takes user name and password; returns a page (logged-in) or throws
    # exception
    def login
      page = @agent.get(@checked_page)
      debug_page_print "front page", page

      login_form = page.form_with(:id => 'frm-loginForm')
      unless login_form
        raise "Login form not found on the index page!"
      end
      login_form['name'] = @config.login
      login_form['password'] = @config.password

      page = @agent.submit(login_form)
      debug_page_print "first logged in", page

      if page.search(".//div[@class='header__user__name']").empty?
        raise "User-menu not found. Login failed or signaly.cz UI changed again."
      end

      return page
    end

    def user_status
      status = Status.new
      page = @agent.get(@checked_page)
      debug_page_print "user main page", page

      menu = page.search(".//header")

      pm = menu.search(".//a[contains(@class, 'header__messages')][1]/span")
      status[:pm] = find_num(pm.text)

      notif = menu.search(".//a[contains(@class, 'header__zvonek')][1]/span")
      status[:notifications] = find_num(notif.text)

      inv = menu.search(".//a[contains(@class, 'header__users')]")
      unless inv.empty?
        inv_count = inv.search('./span')
        status[:invitations] =
          if inv_count.empty?
            1
          else
            find_num(inv_count.text)
          end
      end

      return status
    end

    private

    def debug_page_print(title, page)
      return if ! @dbg_print_pages

      STDERR.puts
      STDERR.puts ColorizedString.new("# "+title).yellow
      STDERR.puts
      STDERR.puts page.root.inner_html
      STDERR.puts
      STDERR.puts "-" * 60
      STDERR.puts
    end

    # finds the first integer in the string and returns it
    def find_num(str, default=0)
      m = str.match /\d+/
      return m ? m[0].to_i : default
    end
  end
end
