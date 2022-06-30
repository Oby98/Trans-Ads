class UsersController < ApplicationController
  before_action :authorized, only: [:auto_login]

  # REGISTER
  def create
    @user = User.create(user_params)
    params.require([:username, :password, :fullname, :email, :phone, :role])
      if @user.valid?
        token = encode_token({user_id: @user.id})
        UserMailer.signup_confirmation(@user).deliver_later
        render json: {user: @user, token: token}, status: 200
      else
        render json: {error: "Invalid credentials"}, status: 400
      end
  end

  # LOGGING IN
  def login
    @user = User.find_by(username: params[:username])

    if @user && @user.authenticate(params[:password])
      token = encode_token({user_id: @user.id})
      render json: {user: @user, token: token}, status: 200
    else
      render json: {error: "Invalid username or password"}, status: 400
    end
  end

  def auto_login
    render json: @user, status: 200
  end

  def show
    @drivers = User.all.where(role: 'driver').pluck(:id, :fullname)
    render json: {drivers: @drivers}, status: 200
  end

  def drivers
    @drivers = User.all.where(role: 'driver')
    render json: {drivers: @drivers}, status: 200
  end

  def update
    if params[:id].blank? or params[:new_password].blank? # check if email is present
      render json: {error: 'ID or Password not present'}, status: 401
    end

    if @user && @user.authenticate(params[:password])
      user = User.find(params[:id])
      user.update_attribute(:password_digest, BCrypt::Password.create(params[:new_password]))
      render json: {message: 'Password has been updated'}, status: 200
    else
      render json: {error: 'Old password is not correct'}, status: 401
    end
  end

  private

  def user_params
    params.permit(:username, :password, :fullname, :email, :phone, :role)
  end

end
