#!/usr/bin/perl
use Ffmpeg;

#################### ATTRIBUTE TESTS ##########################
@TESTS = (
	'<stream index="1" codec_name="h264" codec_long_name="H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10" profile="Baseline" codec_type="video" codec_time_base="1/59936" codec_tag_string="avc1" codec_tag="0x31637661" width="480" height="270" has_b_frames="0" sample_aspect_ratio="1:1" display_aspect_ratio="16:9" pix_fmt="yuv420p" level="21" chroma_location="left" refs="1" is_avc="1" nal_length_size="2" r_frame_rate="3746/125" avg_frame_rate="3746/125" time_base="1/29968" start_pts="0" start_time="0.000000" duration_ts="17666000" duration="589.495462" bit_rate="351918" bits_per_raw_sample="8" nb_frames="17666">',
	'<stream index="0" codec_name="h264" codec_long_name="H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10" profile="Baseline" codec_type="video" codec_time_base="1/59936" codec_tag_string="avc1" codec_tag="0x31637661" width="480" height="270" has_b_frames="0" sample_aspect_ratio="1:1" display_aspect_ratio="16:9" pix_fmt="yuv420p" level="21" chroma_location="left" refs="1" is_avc="1" nal_length_size="2" r_frame_rate="3746/125" avg_frame_rate="3746/125" time_base="1/29968" start_pts="0" start_time="0.000000" duration_ts="150000" duration="5.005339" bit_rate="432472" bits_per_raw_sample="8" nb_frames="150">',
	'<stream index="1" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/44100" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="44100" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/44100" start_pts="0" start_time="0.000000" duration_ts="221184" duration="5.015510" bit_rate="125144" nb_frames="216">',
	'<stream index="0" codec_name="mpeg4" codec_long_name="MPEG-4 part 2" profile="Simple Profile" codec_type="video" codec_time_base="1/25" codec_tag_string="mp4v" codec_tag="0x7634706d" width="720" height="404" has_b_frames="0" sample_aspect_ratio="254:255" display_aspect_ratio="3048:1717" pix_fmt="yuv420p" level="1" chroma_location="left" refs="1" quarter_sample="0" divx_packed="0" r_frame_rate="25/1" avg_frame_rate="25/1" time_base="1/12800" start_pts="-114177" start_time="-8.920078" duration_ts="178688" duration="13.960000" bit_rate="3370412" nb_frames="349">',
	'<stream index="1" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/48000" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="48000" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-428545" start_time="-8.928021" duration_ts="668672" duration="13.930667" bit_rate="127662" nb_frames="653">',
	'<stream index="2" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/48000" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="48000" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-428545" start_time="-8.928021" duration_ts="668672" duration="13.930667" bit_rate="128706" nb_frames="653">',
	'<stream index="3" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="tx3g" codec_tag="0x67337874" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-60000" start_time="-60.000000" duration_ts="427680" duration="427.680000" nb_frames="2">',
	'<stream index="4" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="text" codec_tag="0x74786574" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-8928" start_time="-8.928000" duration_ts="427680" duration="427.680000" bit_rate="38" nb_frames="1">',
	'<stream index="0" codec_name="mpeg4" codec_long_name="MPEG-4 part 2" profile="Simple Profile" codec_type="video" codec_time_base="1/25" codec_tag_string="mp4v" codec_tag="0x7634706d" width="720" height="404" has_b_frames="0" sample_aspect_ratio="254:255" display_aspect_ratio="3048:1717" pix_fmt="yuv420p" level="1" chroma_location="left" refs="1" quarter_sample="0" divx_packed="0" r_frame_rate="25/1" avg_frame_rate="25/1" time_base="1/12800" start_pts="-102127" start_time="-7.978672" duration_ts="166400" duration="13.000000" bit_rate="2134838" nb_frames="325">',
	'<stream index="1" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/48000" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="48000" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-383488" start_time="-7.989333" duration_ts="623616" duration="12.992000" bit_rate="128235" nb_frames="609">',
	'<stream index="2" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/48000" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="48000" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-383488" start_time="-7.989333" duration_ts="623616" duration="12.992000" bit_rate="128103" nb_frames="609">',
	'<stream index="3" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="tx3g" codec_tag="0x67337874" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-42899" start_time="-42.899000" duration_ts="182219" duration="182.219000" nb_frames="2">',
	'<stream index="4" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="text" codec_tag="0x74786574" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-7989" start_time="-7.989000" duration_ts="182219" duration="182.219000" bit_rate="38" nb_frames="1">',
	'<stream index="0" codec_name="h264" codec_long_name="H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10" profile="Main" codec_type="video" codec_time_base="1/50" codec_tag_string="avc1" codec_tag="0x31637661" width="720" height="406" has_b_frames="1" sample_aspect_ratio="406:405" display_aspect_ratio="16:9" pix_fmt="yuv420p" level="41" chroma_location="left" refs="2" is_avc="1" nal_length_size="4" r_frame_rate="25/1" avg_frame_rate="25/1" time_base="1/12800" start_pts="-10752" start_time="-0.840000" duration_ts="75264" duration="5.880000" bit_rate="4174417" bits_per_raw_sample="8" nb_frames="147">',
	'<stream index="1" codec_name="ac3" codec_long_name="ATSC A/52A (AC-3)" codec_type="audio" codec_time_base="1/48000" codec_tag_string="ac-3" codec_tag="0x332d6361" sample_fmt="fltp" sample_rate="48000" channels="6" channel_layout="5.1(side)" bits_per_sample="0" dmix_mode="-1" ltrt_cmixlev="-1.000000" ltrt_surmixlev="-1.000000" loro_cmixlev="-1.000000" loro_surmixlev="-1.000000" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-43008" start_time="-0.896000" duration_ts="284160" duration="5.920000" bit_rate="384000" nb_frames="185">',
	'<stream index="2" codec_name="ac3" codec_long_name="ATSC A/52A (AC-3)" codec_type="audio" codec_time_base="1/48000" codec_tag_string="ac-3" codec_tag="0x332d6361" sample_fmt="fltp" sample_rate="48000" channels="6" channel_layout="5.1(side)" bits_per_sample="0" dmix_mode="-1" ltrt_cmixlev="-1.000000" ltrt_surmixlev="-1.000000" loro_cmixlev="-1.000000" loro_surmixlev="-1.000000" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-43008" start_time="-0.896000" duration_ts="284160" duration="5.920000" bit_rate="384000" nb_frames="185">',
	'<stream index="3" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="tx3g" codec_tag="0x67337874" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-60000" start_time="-60.000000" duration_ts="228480" duration="228.480000" nb_frames="2">',
	'<stream index="4" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="text" codec_tag="0x74786574" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-896" start_time="-0.896000" duration_ts="228480" duration="228.480000" bit_rate="38" nb_frames="1">',
	'<stream index="0" codec_name="h264" codec_long_name="H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10" profile="Main" codec_type="video" codec_time_base="1/50" codec_tag_string="avc1" codec_tag="0x31637661" width="720" height="406" has_b_frames="1" sample_aspect_ratio="406:405" display_aspect_ratio="16:9" pix_fmt="yuv420p" level="41" chroma_location="left" refs="2" is_avc="1" nal_length_size="4" r_frame_rate="25/1" avg_frame_rate="25/1" time_base="1/12800" start_pts="-10479" start_time="-0.818672" duration_ts="75264" duration="5.880000" bit_rate="4174417" bits_per_raw_sample="8" nb_frames="147">',
	'<stream index="1" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/48000" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="48000" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-41472" start_time="-0.864000" duration_ts="281600" duration="5.866667" bit_rate="125847" nb_frames="275">',
	'<stream index="2" codec_name="aac" codec_long_name="AAC (Advanced Audio Coding)" profile="LC" codec_type="audio" codec_time_base="1/48000" codec_tag_string="mp4a" codec_tag="0x6134706d" sample_fmt="fltp" sample_rate="48000" channels="2" channel_layout="stereo" bits_per_sample="0" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/48000" start_pts="-41472" start_time="-0.864000" duration_ts="281600" duration="5.866667" bit_rate="126865" nb_frames="275">',
	'<stream index="3" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="tx3g" codec_tag="0x67337874" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-59979" start_time="-59.979000" duration_ts="228459" duration="228.459000" nb_frames="2">',
	'<stream index="4" codec_name="mov_text" codec_long_name="3GPP Timed Text subtitle" codec_type="subtitle" codec_time_base="1/1000" codec_tag_string="text" codec_tag="0x74786574" r_frame_rate="0/0" avg_frame_rate="0/0" time_base="1/1000" start_pts="-864" start_time="-0.864000" duration_ts="228459" duration="228.459000" bit_rate="38" nb_frames="1">',
);

@TEST_RESULTS = (
	'avg_frame_rate=3746/125 bit_rate=351918 bits_per_raw_sample=8 chroma_location=left codec_long_name=H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 codec_name=h264 codec_tag=0x31637661 codec_tag_string=avc1 codec_time_base=1/59936 codec_type=video display_aspect_ratio=16:9 duration=589.495462 duration_ts=17666000 has_b_frames=0 height=270 index=1 is_avc=1 level=21 nal_length_size=2 nb_frames=17666 pix_fmt=yuv420p profile=Baseline r_frame_rate=3746/125 refs=1 sample_aspect_ratio=1:1 start_pts=0 start_time=0.000000 time_base=1/29968 width=480',
	'avg_frame_rate=3746/125 bit_rate=432472 bits_per_raw_sample=8 chroma_location=left codec_long_name=H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 codec_name=h264 codec_tag=0x31637661 codec_tag_string=avc1 codec_time_base=1/59936 codec_type=video display_aspect_ratio=16:9 duration=5.005339 duration_ts=150000 has_b_frames=0 height=270 index=0 is_avc=1 level=21 nal_length_size=2 nb_frames=150 pix_fmt=yuv420p profile=Baseline r_frame_rate=3746/125 refs=1 sample_aspect_ratio=1:1 start_pts=0 start_time=0.000000 time_base=1/29968 width=480',
	'avg_frame_rate=0/0 bit_rate=125144 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/44100 codec_type=audio duration=5.015510 duration_ts=221184 index=1 nb_frames=216 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=44100 start_pts=0 start_time=0.000000 time_base=1/44100',
	'avg_frame_rate=25/1 bit_rate=3370412 chroma_location=left codec_long_name=MPEG-4 part 2 codec_name=mpeg4 codec_tag=0x7634706d codec_tag_string=mp4v codec_time_base=1/25 codec_type=video display_aspect_ratio=3048:1717 divx_packed=0 duration=13.960000 duration_ts=178688 has_b_frames=0 height=404 index=0 level=1 nb_frames=349 pix_fmt=yuv420p profile=Simple Profile quarter_sample=0 r_frame_rate=25/1 refs=1 sample_aspect_ratio=254:255 start_pts=-114177 start_time=-8.920078 time_base=1/12800 width=720',
	'avg_frame_rate=0/0 bit_rate=127662 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/48000 codec_type=audio duration=13.930667 duration_ts=668672 index=1 nb_frames=653 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-428545 start_time=-8.928021 time_base=1/48000',
	'avg_frame_rate=0/0 bit_rate=128706 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/48000 codec_type=audio duration=13.930667 duration_ts=668672 index=2 nb_frames=653 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-428545 start_time=-8.928021 time_base=1/48000',
	'avg_frame_rate=0/0 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x67337874 codec_tag_string=tx3g codec_time_base=1/1000 codec_type=subtitle duration=427.680000 duration_ts=427680 index=3 nb_frames=2 r_frame_rate=0/0 start_pts=-60000 start_time=-60.000000 time_base=1/1000',
	'avg_frame_rate=0/0 bit_rate=38 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x74786574 codec_tag_string=text codec_time_base=1/1000 codec_type=subtitle duration=427.680000 duration_ts=427680 index=4 nb_frames=1 r_frame_rate=0/0 start_pts=-8928 start_time=-8.928000 time_base=1/1000',
	'avg_frame_rate=25/1 bit_rate=2134838 chroma_location=left codec_long_name=MPEG-4 part 2 codec_name=mpeg4 codec_tag=0x7634706d codec_tag_string=mp4v codec_time_base=1/25 codec_type=video display_aspect_ratio=3048:1717 divx_packed=0 duration=13.000000 duration_ts=166400 has_b_frames=0 height=404 index=0 level=1 nb_frames=325 pix_fmt=yuv420p profile=Simple Profile quarter_sample=0 r_frame_rate=25/1 refs=1 sample_aspect_ratio=254:255 start_pts=-102127 start_time=-7.978672 time_base=1/12800 width=720',
	'avg_frame_rate=0/0 bit_rate=128235 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/48000 codec_type=audio duration=12.992000 duration_ts=623616 index=1 nb_frames=609 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-383488 start_time=-7.989333 time_base=1/48000',
	'avg_frame_rate=0/0 bit_rate=128103 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/48000 codec_type=audio duration=12.992000 duration_ts=623616 index=2 nb_frames=609 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-383488 start_time=-7.989333 time_base=1/48000',
	'avg_frame_rate=0/0 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x67337874 codec_tag_string=tx3g codec_time_base=1/1000 codec_type=subtitle duration=182.219000 duration_ts=182219 index=3 nb_frames=2 r_frame_rate=0/0 start_pts=-42899 start_time=-42.899000 time_base=1/1000',
	'avg_frame_rate=0/0 bit_rate=38 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x74786574 codec_tag_string=text codec_time_base=1/1000 codec_type=subtitle duration=182.219000 duration_ts=182219 index=4 nb_frames=1 r_frame_rate=0/0 start_pts=-7989 start_time=-7.989000 time_base=1/1000',
	'avg_frame_rate=25/1 bit_rate=4174417 bits_per_raw_sample=8 chroma_location=left codec_long_name=H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 codec_name=h264 codec_tag=0x31637661 codec_tag_string=avc1 codec_time_base=1/50 codec_type=video display_aspect_ratio=16:9 duration=5.880000 duration_ts=75264 has_b_frames=1 height=406 index=0 is_avc=1 level=41 nal_length_size=4 nb_frames=147 pix_fmt=yuv420p profile=Main r_frame_rate=25/1 refs=2 sample_aspect_ratio=406:405 start_pts=-10752 start_time=-0.840000 time_base=1/12800 width=720',
	'avg_frame_rate=0/0 bit_rate=384000 bits_per_sample=0 channel_layout=5.1(side) channels=6 codec_long_name=ATSC A/52A (AC-3) codec_name=ac3 codec_tag=0x332d6361 codec_tag_string=ac-3 codec_time_base=1/48000 codec_type=audio dmix_mode=-1 duration=5.920000 duration_ts=284160 index=1 loro_cmixlev=-1.000000 loro_surmixlev=-1.000000 ltrt_cmixlev=-1.000000 ltrt_surmixlev=-1.000000 nb_frames=185 r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-43008 start_time=-0.896000 time_base=1/48000',
	'avg_frame_rate=0/0 bit_rate=384000 bits_per_sample=0 channel_layout=5.1(side) channels=6 codec_long_name=ATSC A/52A (AC-3) codec_name=ac3 codec_tag=0x332d6361 codec_tag_string=ac-3 codec_time_base=1/48000 codec_type=audio dmix_mode=-1 duration=5.920000 duration_ts=284160 index=2 loro_cmixlev=-1.000000 loro_surmixlev=-1.000000 ltrt_cmixlev=-1.000000 ltrt_surmixlev=-1.000000 nb_frames=185 r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-43008 start_time=-0.896000 time_base=1/48000',
	'avg_frame_rate=0/0 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x67337874 codec_tag_string=tx3g codec_time_base=1/1000 codec_type=subtitle duration=228.480000 duration_ts=228480 index=3 nb_frames=2 r_frame_rate=0/0 start_pts=-60000 start_time=-60.000000 time_base=1/1000',
	'avg_frame_rate=0/0 bit_rate=38 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x74786574 codec_tag_string=text codec_time_base=1/1000 codec_type=subtitle duration=228.480000 duration_ts=228480 index=4 nb_frames=1 r_frame_rate=0/0 start_pts=-896 start_time=-0.896000 time_base=1/1000',
	'avg_frame_rate=25/1 bit_rate=4174417 bits_per_raw_sample=8 chroma_location=left codec_long_name=H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 codec_name=h264 codec_tag=0x31637661 codec_tag_string=avc1 codec_time_base=1/50 codec_type=video display_aspect_ratio=16:9 duration=5.880000 duration_ts=75264 has_b_frames=1 height=406 index=0 is_avc=1 level=41 nal_length_size=4 nb_frames=147 pix_fmt=yuv420p profile=Main r_frame_rate=25/1 refs=2 sample_aspect_ratio=406:405 start_pts=-10479 start_time=-0.818672 time_base=1/12800 width=720',
	'avg_frame_rate=0/0 bit_rate=125847 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/48000 codec_type=audio duration=5.866667 duration_ts=281600 index=1 nb_frames=275 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-41472 start_time=-0.864000 time_base=1/48000',
	'avg_frame_rate=0/0 bit_rate=126865 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/48000 codec_type=audio duration=5.866667 duration_ts=281600 index=2 nb_frames=275 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=48000 start_pts=-41472 start_time=-0.864000 time_base=1/48000',
	'avg_frame_rate=0/0 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x67337874 codec_tag_string=tx3g codec_time_base=1/1000 codec_type=subtitle duration=228.459000 duration_ts=228459 index=3 nb_frames=2 r_frame_rate=0/0 start_pts=-59979 start_time=-59.979000 time_base=1/1000',
	'avg_frame_rate=0/0 bit_rate=38 codec_long_name=3GPP Timed Text subtitle codec_name=mov_text codec_tag=0x74786574 codec_tag_string=text codec_time_base=1/1000 codec_type=subtitle duration=228.459000 duration_ts=228459 index=4 nb_frames=1 r_frame_rate=0/0 start_pts=-864 start_time=-0.864000 time_base=1/1000',
);

my $ffmpeg = new Ffmpeg();
my $errorCount = 0;
my $totalCount = scalar(@TESTS);
for ($i=0; $i<scalar(@TESTS); $i++) {
	my $desc = $ffmpeg->parseAttributes($TESTS[$i]);
	my $actual = $ffmpeg->getStreamString($desc);
	if ($actual ne $TEST_RESULTS[$i]) {
		print "Attribute Test $i failed.\n   Expected: $TEST_RESULTS[$i]\n   Actual:   $actual\n";
		$errorCount++;
	}
}

######################## ANALYZE TESTS ##########################


if (-f "test1.mp4") {
	$totalCount += 5;
	$desc = $ffmpeg->analyze("test1.mp4");
	$expected = 'avg_frame_rate=3746/125 bit_rate=432472 bits_per_raw_sample=8 chroma_location=left codec_long_name=H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 codec_name=h264 codec_tag=0x31637661 codec_tag_string=avc1 codec_time_base=1/59936 codec_type=video default=1 display_aspect_ratio=16:9 duration=5.005339 duration_ts=150000 has_b_frames=0 height=270 index=0 is_avc=1 languageCode=und level=21 nal_length_size=2 nb_frames=150 pix_fmt=yuv420p profile=Baseline r_frame_rate=3746/125 refs=1 sample_aspect_ratio=1:1 start_pts=0 start_time=0.000000 time_base=1/29968 width=480';
	$actual   = $ffmpeg->getStreamString($desc->{video}->{0});
	if ($actual ne $expected) {
		print "Video Stream Test failed.\n    Expected: $expected\n    Actual:   $actual\n";
		$errorCount++;
	}

	$expected = 'avg_frame_rate=0/0 bit_rate=125144 bits_per_sample=0 channel_layout=stereo channels=2 codec_long_name=AAC (Advanced Audio Coding) codec_name=aac codec_tag=0x6134706d codec_tag_string=mp4a codec_time_base=1/44100 codec_type=audio default=1 duration=5.015510 duration_ts=221184 index=1 languageCode=und nb_frames=216 profile=LC r_frame_rate=0/0 sample_fmt=fltp sample_rate=44100 start_pts=0 start_time=0.000000 time_base=1/44100';
	$actual   = $ffmpeg->getStreamString($desc->{audio}->{1});
	if ($actual ne $expected) {
		print "Audio Stream Test failed.\n    Expected: $expected\n    Actual:   $actual\n";
		$errorCount++;
	}

	$errorCount += testCompatibility($ffmpeg, "test1.mp4", 1, 1);

	$expected = 'Video: h264 / Audio: unknown (aac)';
	$actual = $ffmpeg->getShortSummary($desc);
	if ($actual ne $expected) {
		print "Analysis Test failed.\n    Expected: $expected\n    Actual:   $actual\n";
		$errorCount++;
	}
} else {
	print "Warning: Cannot test video file: /var/test.mp4\n";
}

# test2.mp4 Apple OK - BBT-S01E01
if (-f "test2.mp4") {
	$totalCount += 2;
	$errorCount += testCompatibility($ffmpeg, "test2.mp4", 1, 1);
}

# test3.mp4 Apple OK  - BBT-S06E01
if (-f "test3.mp4") {
	$totalCount += 2;
	$errorCount += testCompatibility($ffmpeg, "test3.mp4", 1, 1);
}

# test4.mp4 Apple NOK / AC3 - BTF2
if (-f "test4.mp4") {
	$totalCount += 2;
	$errorCount += testCompatibility($ffmpeg, "test4.mp4", 0, 1);
}

# test5.mp4 Apple OK - BTF2-iPhone
if (-f "test5.mp4") {
	$totalCount += 2;
	$errorCount += testCompatibility($ffmpeg, "test5.mp4", 1, 1);
}

if ($errorCount) {
	print "$errorCount / $totalCount tests failed\n";
	exit 1;
}

print "Successful. $totalCount tests executed.\n";
exit 0;

sub testCompatibility {
	my $ffmpeg = shift;
	my $file   = shift;
	my $expectedApple = shift;
	my $expectedEnigma = shift;
	my $errorCount = 0;

	my $desc = $ffmpeg->analyze($file);
	my $actual = $ffmpeg->isAppleCompatible($desc);
	if ($actual != $expectedApple) {
		print "$file: Apple Compatibility Test failed.\n    Expected: $expectedApple\n    Actual:   $actual\n";
		$errorCount++;
	}
	$actual = $ffmpeg->isEnigmaCompatible($desc);
	if ($actual != $expectedEnigma) {
		print "$file: Enigma Compatibility Test failed.\n    Expected: $expectedEnigma\n    Actual:   $actual\n";
		$errorCount++;
	}

	return $errorCount;
}

