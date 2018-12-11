# Copyright (C) 2013 Devin Breen
# This file is part of dogtag <https://github.com/chiditarod/dogtag>.
#
# dogtag is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dogtag is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dogtag.  If not, see <http://www.gnu.org/licenses/>.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # SSL
  force_ssl :if => :is_production?

  helper :all
  helper_method :current_user_session, :current_user

  # Fix for cancan and rails4
  # Seeing if this is needed any more for cancancan 2.x and rails 5.x
  #before_filter do
    #resource = controller_name.singularize.to_sym
    #method = "#{resource}_params"
    #params[resource] &&= send(method) if respond_to?(method, true)
  #end

  # rescue_from ORDERING MATTERS.  Start generic first
  unless Rails.configuration.consider_all_requests_local
    rescue_from Exception, :with => :render_error
    rescue_from ActionController::RoutingError, :with => :render_not_found
    rescue_from ActionController::UnknownController, :with => :render_not_found
    rescue_from CanCan::AccessDenied, :with => :render_access_denied
  end
  # we always want these (including during tests)
  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::ParameterMissing, :with => :render_400

  def should_run_update_checker
    return false if params['controller'] == 'users' && %w(edit update).include?(params['action'])
    return false if params['controller'] == 'user_sessions' && params['action'] == 'destroy'
    true
  end

  private

  def is_production?
    Rails.env == 'production'
  end

  def render_not_found(ex)
    log_error(ex)
    render template: "/error/404.html.erb", status: 404
  end

  def render_400(ex)
    log_error(ex)
    render template: "/error/400.html.erb", status: 400
  end

  def render_access_denied(ex)
    log_error(ex)
    redirect_to home_url, :alert => ex.message
  end

  def render_error(ex)
    log_error(ex)
    render template: "/error/500.html.erb", status: 500
  end

  def log_error(ex)
    Rails.logger.error "#{ex.class} #{ex.message}"
  end

  ## common functions used in controllers ------

  def try_to_update(obj_to_update, attributes_to_apply, redirect_to_url, success_msg='update_success')
    if obj_to_update.update_attributes(attributes_to_apply)
      flash[:notice] = I18n.t(success_msg)
      redirect_to(redirect_to_url)
    else
      flash.now[:error] = [I18n.t('update_failed')]
      flash.now[:error] << obj_to_update.errors.messages
    end
  end

  def try_to_delete(obj, redirect_url)
    if obj.destroy
      flash[:notice] = I18n.t('delete_success')
    else
      flash[:error] = I18n.t('destroy_failed')
    end
    redirect_to(redirect_url)
  end

  ## user/session stuff -----------------------------------------

  def current_user_session
    return @current_user_session if defined? @current_user_session
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined? @current_user
    @current_user = current_user_session && current_user_session.record
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_path
      return false
    end

    user_update_checker
  end

  # if the current_user's User object is invalid, there's been a change in the underlying
  # validation. redirect user to update their info.
  def user_update_checker
    if should_run_update_checker
      user = User.find(current_user.id)
      if user.invalid?
        flash[:notice] = t('users.review_your_info')
        return redirect_to edit_user_url(user)
      end
    end
  end

  def require_no_user
    if current_user
      flash[:notice] = "You must be logged out to access this page"
      redirect_back_or_default account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.original_url
    #todo: remove this logging once it works
    logger.info "-----------------"
    logger.info session[:return_to]
    logger.info "-----------------"
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end
