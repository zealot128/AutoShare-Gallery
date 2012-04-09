class PhotosController < ApplicationController

  before_filter :http_basic_auth, only: :create
  before_filter :login_required

  def index
    @groups = Photo.grouped
  end

  def destroy
    @photo = current_user.photos.find(params[:id])
    @photo.destroy
    redirect_to photos_path
  end

  def shared

    response.headers['Content-Type'] = 'image/jpeg'
    response.headers['Content-Disposition'] = 'inline'

    path = Photo.find_by_share_hash!(params[:hash]).path(:large)
    render :text => open(path, "rb").read
  end

  protect_from_forgery except: :create
  def create
    Photo.create_from_upload(params[:userfile], current_user)

    current_user.enable_ip_based_login request

    render :text => "OK"
  end

  protected
  def http_basic_auth
    return true if current_user

    authenticate_or_request_with_http_basic do |username, password|
      by_username = User.authenticate(username, password)
      by_ip       = User.authenticate_by_ip(request)
      p by_username
      p by_ip

      if ( user = by_username || by_ip )
        session[:user_id] = user.id
        p user
        true
      else
        false
      end
    end

  end

end
