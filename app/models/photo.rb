class Photo < ActiveRecord::Base
  has_attached_file :file, styles: {
    preview:  "300x300",
    medium: "500x500>",
    large:  "1000x1000>"
  },
  path:   ":rails_root/public/photos/:style/:date/:basename.:extension",
  url:    "/photos/:style/:date/:basename.:extension",
  convert_options: { all: '-auto-orient' }

  belongs_to :user

  before_save do
    self.share_hash = SecureRandom.hex(24)
  end

  def self.parse_date(file)
    meta = EXIFR::JPEG.new(file.path)
    date = meta.exif[:date_time] || meta.exif[:date_time_original] rescue nil
    if not date
      if file.original_filename[/(\d{4})[\-_\.](\d{2})[\-_\.](\d{2})/]
        date = Date.parse "#$1-#$2-#$3"
      else
        Rails.logger.warn "No Date found for file #{file.original_filename}"
        date = Date.today
      end
    end
    if date.is_a? String
      case date
      # correction for exif from hd cam
      when /^(\d{4}):(\d{1,2}):(\d{1,2})/
        date = Date.parse("#$1-#$2-#$3")
      else
        date = Date.parse(date)
      end
    end
    date
  end


  def self.create_from_upload(file, current_user)

    photo = Photo.new

    date = Photo.parse_date(file)

    meta = EXIFR::JPEG.new(file.path)
    if meta.gps
      photo.lat = meta.gps.latitude
      photo.lng = meta.gps.longitude
    end

    photo.shot_at = date.to_date
    photo.user = current_user
    photo.file = file
    photo.save
    photo.reverse_geocode
  end

  reverse_geocoded_by :lat, :lng do |obj,results|
    if geo = results.first
      parts = [geo.city]
      parts << geo.address_components_of_type("establishment").first["short_name"]  rescue nil
      parts << geo.address_components_of_type("sublocality").first["short_name"] rescue nil
      obj.update_attribute(:location, parts.join(" - "))
    end
  end

  def exif
    meta_data.exif.inject({}) {|a,e| a.merge e}
  end

  def meta_data
    @meta_data ||= EXIFR::JPEG.new(file.path)
  end

  def update_gps
    if gps = meta_data.gps
      self.lat = gps.latitude
      self.lng = gps.longitude
      reverse_geocode
    end
  end

  def self.grouped
    days = Photo.all.group_by{|i|i.shot_at.to_date}.sort_by{|a,b| a}.reverse
    #  [datum, [items]] ...
    #  [month, [ [datum, items], ...

    days.group_by{|day, items| Date.parse day.strftime("%Y-%m-01")}
  end

  scope :dates, group(:shot_at).select(:shot_at).order("shot_at desc")
end
