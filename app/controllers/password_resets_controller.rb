# Copyright (C) 2015 Devin Breen
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
class PasswordResetsController < ApplicationController
  # Method from: http://github.com/binarylogic/authlogic_example/blob/master/app/controllers/application_controller.rb
  before_action :require_no_user
  before_action :load_user_using_perishable_token, :only => [ :edit, :update ]

  def new
  end

  def create
    unless params[:email].present?
      flash.now[:error] = "No email address provided."
      return render action: :new, status: :bad_request
    end

    @user = User.find_by_email(params[:email].downcase)

    if @user
      @user.reset_password!(request.host_with_port)
      flash[:notice] = "Instructions to reset your password have been emailed to you"
      redirect_to home_url
    else
      flash.now[:error] = "No user was found with email address: #{params[:email]}"
      render action: :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    unless params[:password].present? && params[:password_confirmation].present?
      flash[:error] = 'Ensure you supply a new password and confirmation'
      return render :action => :edit
    end

    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    # Use @user.save_without_session_maintenance instead if you
    # don't want the user to be signed in automatically.
    if @user.save
      flash[:notice] = "Your password was successfully updated"
      redirect_to user_url(@user.id)
    else
      flash[:error] = @user.errors.messages
      render :action => :edit
    end
  end

  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:error] = "We're sorry, but we could not locate your account"
      redirect_to home_url
    end
  end
end
