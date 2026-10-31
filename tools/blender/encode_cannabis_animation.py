"""Encode Godot MJPEG to H.264 with Blender's bundled FFmpeg."""
from pathlib import Path
import bpy
root=Path(__file__).resolve().parents[2];out=root/'out/blender'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
editor=scene.sequence_editor_create()
clip=editor.strips.new_movie('CannabisGrowth',str(out/'cannabis_growth_animations.avi'),channel=1,frame_start=1)
scene.frame_start=3;scene.frame_end=clip.frame_final_duration
scene.render.fps=24
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.render.use_sequencer=True;scene.view_settings.view_transform='Standard'
scene.render.image_settings.media_type='VIDEO';scene.render.image_settings.file_format='FFMPEG'
scene.render.ffmpeg.format='MPEG4';scene.render.ffmpeg.codec='H264'
scene.render.ffmpeg.constant_rate_factor='MEDIUM';scene.render.ffmpeg.ffmpeg_preset='GOOD';scene.render.ffmpeg.audio_codec='NONE'
scene.render.filepath=str(out/'cannabis_growth_animations.mp4')
bpy.ops.render.render(animation=True)
print('ENCODED',scene.render.filepath)
