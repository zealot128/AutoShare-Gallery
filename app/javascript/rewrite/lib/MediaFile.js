import dayjs from 'utils/dayjs'

class MediaFile {
  constructor(data) {
    this.id = data.id
    this.data = data;
    this.title = data.shot_at_formatted
    this.exif = data.exif
    this.href = data.versions.large
    this.preview = data.versions.preview
    this.shotAt = dayjs(data.shot_at)
    if (data.type === 'Video') {
      this.type = 'video/mp4'
      this.poster = this.preview
    } else {
      this.type = 'image/jpeg'
      this.thumbnail = data.versions.thumb
    }
    this.isLiked = data.liked_by.length > 0
  }
}

export default MediaFile


