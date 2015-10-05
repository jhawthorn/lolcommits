# -*- encoding : utf-8 -*-
module Lolcommits
  class CaptureLinuxAnimated < Capturer
    def capture
      # make a fresh frames directory
      FileUtils.rm_rf(frames_location)
      FileUtils.mkdir_p(frames_location)

      # capture the raw video with ffmpeg video4linux2
      system_call "ffmpeg -v quiet -y -f video4linux2 -video_size 320x240 -i #{capture_device_string} -t #{capture_duration} #{video_location} > /dev/null"
      return unless File.exist?(video_location)

      filters="fps=15,scale=320:-1:flags=lanczos"

      palette_location="/tmp/palette.png"

      system_call %{ffmpeg -v warning -i #{video_location} -vf "#{filters},palettegen" -y #{palette_location}}
      system_call %{ffmpeg -v warning -i #{video_location} -i #{palette_location} -lavfi "#{filters} [x]; [x][1:v] paletteuse" -y #{snapshot_location}}
    end

    private

    def system_call(call_str, capture_output = false)
      debug "Capturer: making system call for \n #{call_str}"
      capture_output ? `#{call_str}` : system(call_str)
    end

    def frame_delay(fps, skip)
      # calculate frame delay
      delay = ((100.0 * skip) / fps.to_f).to_i
      delay < 6 ? 6 : delay # hard limit for IE browsers
    end

    def video_fps(file)
      # inspect fps of the captured video file (default to 29.97)
      fps = system_call("ffmpeg -i #{file} 2>&1 | sed -n \"s/.*, \\(.*\\) fp.*/\\1/p\"", true)
      fps.to_i < 1 ? 29.97 : fps.to_f
    end

    def frame_skip(fps)
      # of frames to skip depends on movie fps
      case (fps)
      when 0..15
        2
      when 16..28
        3
      else
        4
      end
    end

    def capture_device_string
      capture_device || '/dev/video0'
    end

    def capture_delay_string
      " -ss #{capture_delay}" if capture_delay.to_i > 0
    end

    def capture_duration
      animated_duration.to_i + capture_delay.to_i
    end
  end
end
