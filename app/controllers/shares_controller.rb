class SharesController < ApplicationController
  before_action :login_required, except: "show"

  def show
    @share = Share.find_by!(token: params[:id])
    @photos = @share.photos.order("shot_at asc")
  end

  def destroy
    @share = Share.find_by_token(params[:id])
    @share.destroy
    respond_to do |f|
      f.js
    end
  end
end
