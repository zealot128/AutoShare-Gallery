require 'spec_helper'

describe Photo do

  let :picture do
    Rails.root.join("spec/fixtures/tiger.jpg")
  end

  let :other_picture do
    Rails.root.join("spec/fixtures/somestuff.jpg")
  end

  let :user do
    valid_user
  end

  it "should store the uniq by hash" do
    photo = Photo.create_from_upload(File.open(picture.to_s), user)
    photo.md5.should == Digest::MD5.hexdigest( picture.read )
  end

  it "should validate by uniqness" do
    photo = Photo.create_from_upload(File.open(picture.to_s), user)

    expect {
      photo = Photo.create_from_upload(File.open(picture.to_s), user)
    }.to_not change(Photo, :count)
  end

  specify "after saving should create or initialize respective day" do
    photo = nil
    expect {
      photo = Photo.create_from_upload(File.open(picture.to_s), user)
    }.to change(Day, :count)

    photo.day.should be_present
    Day.last.tap do |day|
      day.date.should == photo.shot_at.to_date
      day.year.should == photo.shot_at.year
    end
  end

  specify "Reusing created date" do
    d = Day.create date: Date.parse("2004-09-12")
    photo = nil
    expect {
      photo = Photo.create_from_upload(File.open(other_picture), user)
    }.to_not change(Day, :count)
    photo.day.should == d
    photo.reload.day.should == d
  end

  specify "Changing the date should move the file" do
    Photo.slow_callbacks = true
    photo = Photo.create_from_upload(File.open(picture.to_s), user)
    day = photo.day
    day.should_receive(:update_me)
    photo.update_attributes(:shot_at => Time.parse("2012-10-01 12:00"))
    photo.reload
    File.exists?(photo.file.path).should be_true

    photo.file.versions.each do |key,version|
      File.exists?(version.path).should be_true
    end

    old_path = photo.file.path.gsub('/2012/','/2010/').gsub('2012-10-01', day.date.to_s)
    File.exists?(old_path).should be_false

    Day.where(date: "2012-10-01").first.tap do |d|
      d.photos.should == [photo]
    end
  end

  specify 'EOS600d date format' do
    picture = "spec/fixtures/eos600.jpg"
    photo = Photo.create_from_upload(File.open(picture.to_s), user)
    photo.shot_at.should ==  DateTime.parse("2014-02-05T14:17:42+01:00")
  end

  specify 'Metadata' do
    picture = "spec/fixtures/eos600.jpg"
    photo = Photo.create_from_upload(File.open(picture.to_s), user)
    photo.as_json.should be_present
    photo.exif['model'].should == 'GT-N7100'
  end

  specify 'geocoding' do
    picture = "spec/fixtures/geocode.jpg"
    photo = Photo.create_from_upload(File.open(picture.to_s), user)
    photo.location.should == 'Hofheim am Taunus - Wallau'
  end

  if Rails.application.config.features.ocr
    specify "OCR" do
      photo = Photo.create_from_upload(File.open("spec/fixtures/text.jpg"), user)
      photo.ocr
      photo.description.should include "Mietsteigerung"
    end
  end

  describe 'FOG' do
    around do |ex|
      config = YAML.load_file('config/secrets.yml')['development']
      load_fog(config['fog'])
      ImageUploader.storage :fog
      begin
        ex.run
      ensure
        ImageUploader.storage :file
      end
    end

    specify 'photo upload + rename' do
      Photo.slow_callbacks = true
      photo = Photo.create_from_upload(File.open(picture.to_s), user)

      photo.file.file.exists?.should be == true
      old_path = photo.file.file.path
      day = photo.day
      day.should_receive(:update_me)
      photo.update_attributes(:shot_at => Time.parse("2012-10-01 12:00"))
      photo = Photo.find photo.id
      photo.file.file.exists?.should be == true
      photo.file.path.should be == 'photos/original/2012/2012-10-01/tiger.jpg'
      photo.file.versions.each do |key,version|
        version.file.exists?.should be == true
      end

      f = photo.file.file
      f.instance_variable_set('@path', old_path)
      f.exists?.should be == false
    end
  end
end
