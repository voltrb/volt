class MainController < Volt::ModelController
  model :page

  def index
    a = {}
    a[{}] = 5
    puts a[{}].inspect
  end

  def flash_notice
    flash._notices << 'A notice message'
  end

  def flash_success
    flash._successes << 'A success message'
  end

  def flash_warning
    flash._warnings << 'A warning message'
  end

  def flash_error
    flash._errors << 'An error message'
  end

  def cookie_test
    self.model = page._new_cookie.buffer
  end

  def add_cookie
    cookies.send(:"_#{_name.to_s}=", _value)

    self.model = page._new_cookie.buffer
  end

  private

  # the main template contains a #template binding that shows another
  # template.  This is the path to that template.  It may change based
  # on the params._controller and params._action values.
  def main_path
    params._controller.or('main') + '/' + params._action.or('index')
  end
end
