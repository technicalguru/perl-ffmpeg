package Ffmpeg;
use strict;

my $FFMPEG_ROOT = '/usr/local/ffmpeg';
my $FFMPEG_BIN  = "$FFMPEG_ROOT/ffmpeg";
my $FFPROBE_BIN = "$FFMPEG_ROOT/ffprobe";
my $ENCODERS = {
	# Video
	'ffv' => 'ffv1',
	'flv' => 'flv',
	'h261' => 'h261',
	'h263' => 'h263',
	'h264' => 'libx264',
	'h265' => 'libx265',
	'mpeg1video' => 'mpeg1video',
	'mpeg2video' => 'mpeg2video',
	'mpeg4' => 'libxvid',
	'wmv' => 'wmv2',
	# Audio
	'aac' => 'libvo_aacenc',
	'ac3' => 'ac3_fixed',
	'flac' => 'flac',
	'mp2' => 'mp2',
	'mp3' => 'libmp3lame',
	'vorbis' => 'libvorbis',
	'wma' => 'wmav2',
	# Subtitles
	'dvb_subtitle' => 'dvbsub',
	'dvd_subtitle' => 'dvdsub',
	'mov_text' => 'mov_text',
	'ssa' => 'ssa',
	'srt' => 'srt',
	'subrip' => 'subrip',
	'webvtt' => 'webvtt',
	'xsub' => 'xsub',
};

sub new {
	my $self = {};
	bless($self);
	return $self;
}

# @returns hashref:
# [
#    'video' => [
#        <stream-id>* => [ <video-description> ]
#    ],
#    'audio' => [
#        <stream-id>* => [ <audio-description> ]
#    ],
#    'subtitle' => [
#        <stream-id>* => [ <subtitles-description> ]
#    ]
# ]
#
# <video-description>     - see function parseVideoDesc
# <audio-description>     - see function parseAudioDesc
# <subtitles-description> - see function parseSubtitlesDesc
#
sub analyze {
	my $self = shift;
	my $file = shift;
	my $rc = {
		'video' => {},
		'audio' => {},
		'subtitle' => {},
	};

	my $cmd = "$FFPROBE_BIN -v quiet -print_format xml -show_format -show_streams $file";
	if (open(CMDIN, "$cmd 2>\&1|")) {
		my ($streamId, $streamType);

		while (<CMDIN>) {
			chomp;
			my $line = $_;
			if ($line =~ /^\s*<stream index="(\d+)"/i) {
				$streamId   = $1;
				my $attributes = $self->parseAttributes($line);
				$streamType = $attributes->{codec_type};
				$rc->{$streamType}->{$streamId} = $attributes;
			} elsif ($line =~ /^\s*<tag key="language" value="(.*)"\/>\s*$/) {
				$rc->{$streamType}->{$streamId}->{languageCode} = $1;
			} elsif ($line =~ /^\s*<disposition default="(\d)"/i) {
				$rc->{$streamType}->{$streamId}->{default} = $1;
			} elsif ($line =~ /^\s*<format\s+/i) {
				$rc->{format} = $self->parseAttributes($line);
				$rc->{filename} = $rc->{format}->{filename};
				$streamType = 'format'; # will put all other attributes there
			}

		}
		close(CMDIN);
	} else {
		return 0;
	}
	return $rc;
}

# Returns list of all stream strings
sub getLongSummary {
	my $self = shift;
	my $desc = shift;
	my $stream;
	my @RC = ();

	foreach $stream (sort(keys(%{$desc->{video}}))) {
		push(@RC, $self->getStreamString($desc->{video}->{$stream}));
	}
	foreach $stream (sort(keys(%{$desc->{audio}}))) {
		push(@RC, $self->getStreamString($desc->{audio}->{$stream}));
	}
	foreach $stream (sort(keys(%{$desc->{subtitle}}))) {
		push(@RC, $self->getStreamString($desc->{subtitle}->{$stream}));
	}
	return \@RC;
}

# Returns short description string
sub getShortSummary {
	my $self = shift;
	my $desc = shift;
	my $stream;

	my @VIDEO = ();
	foreach $stream (keys(%{$desc->{video}})) {
		my $lang = $desc->{video}->{$stream}->{'languageCode'};
		$lang = '' if $lang eq 'und';
		if ($lang) {
			push(@VIDEO, $desc->{video}->{$stream}->{codec_name}." ($lang)");
		} else {
			push(@VIDEO, $desc->{video}->{$stream}->{codec_name});
		}
	}
	my @AUDIO = ();
	foreach $stream (keys(%{$desc->{audio}})) {
		my $lang = $desc->{audio}->{$stream}->{'languageCode'};
		$lang = 'unknown' if !$lang || ($lang eq 'und');
		push(@AUDIO, "$lang (".$desc->{audio}->{$stream}->{codec_name}.")");
	}
	my @SUBTITLES = ();
	foreach $stream (keys(%{$desc->{subtitle}})) {
		my $lang = $desc->{subtitle}->{$stream}->{'languageCode'};
		$lang = $desc->{subtitle}->{$stream}->{'languageId'} if !$lang;
		$lang = 'unknown' if !$lang;
		push(@SUBTITLES, "$lang (".$desc->{subtitle}->{$stream}->{codec_name}.")");
	}

	my $rc = "Video: ".join(', ', @VIDEO)." / Audio: ".join(', ', @AUDIO);
	if (@SUBTITLES) {
		$rc .= " / Subtitles: ".join(', ', @SUBTITLES);
	}

	return $rc;
}

# parses an XML begin tag for attributes
# @param $line - string - tag
# @returns hashref - all attributes as key-value pairs
sub parseAttributes {
	my $self = shift;
	my $line = shift;
	my $rc = {};

	# iterate over pairs
	while ($line =~ /([A-Za-z0-9_-]+)="([^"]*)"/g) {
		$rc->{$1} = $2;
	}

	return $rc;
}

# creates a debug string for given stream
# @param $streamDesc - hashref - stream description
# @returns string - debug string
sub getStreamString {
	my $self = shift;
	my $streamDesc = shift;
	my $rc = '';
	my $key;

	foreach $key (sort(keys(%{$streamDesc}))) {
		$rc .= " $key=".$streamDesc->{$key};
	}
	$rc =~ s/^\s+//g;
	return $rc;
}

# Applies codecs for Apple.
# @param $fromDescription - hashref - source description (see analyze function)
# @returns hashref - target description (see analyze function)
sub applyAppleFormats {
	my $self = shift;
	my $fromDescription = shift;

	my $rc = $self->applyFormats(
		$fromDescription,
		$self->getAppleVideo(),
		$self->getAppleAudio(),
		$self->getAppleSubtitles()
	);

	if ($rc->{filename} !~ /\.mp4/i) {
		$rc->{filename} =~ s/\.[a-z0-9]+$/\.mp4/i;
	}

	return $rc;
}

# Returns standard iOS video codec: MPEG4
# @returns arrayref - preference of video codecs (see applyFormats function)
sub getAppleVideo {
	my $self = shift;

	my @RC = (
		{ 'codec' => 'h264' },
		{ 'codec' => 'mpeg4' },
	);
	return \@RC;
}

# Returns standard iOS audio codec: AAC (LC)
# @returns arrayref - preference of audio codecs (see applyFormats function)
sub getAppleAudio {
	my $self = shift;

	my @RC = (
		{ 'codec' => 'aac', 'profile' => 'LC' },
	);
	return \@RC;
}

# Returns standard iOS subtitles codec: SRT
# @returns arrayref - preference of subtitle codecs (see applyFormats function)
sub getAppleSubtitles {
	my $self = shift;

	my @RC = (
		{ 'codec' => 'srt' },
	);
	return \@RC;
}

# Returns true when description is compatible with Apple devices.
sub isAppleCompatible {
	my $self = shift;
	my $desc = shift;

	return $self->isCompatible($desc, $self->getAppleVideo(), $self->getAppleAudio(), $self->getAppleSubtitles()) &&
		($desc->{format}->{format_name} eq 'mov,mp4,m4a,3gp,3g2,mj2');
}

# Applies codecs for Enigma.
# @param $fromDescription - hashref - source description (see analyze function)
# @returns hashref - target description (see analyze function)
sub applyEnigmaFormats {
	my $self = shift;
	my $fromDescription = shift;

	return $self->applyFormats(
		$fromDescription,
		$self->getEnigmaVideo(),
		$self->getEnigmaAudio(),
		$self->getEnigmaSubtitles()
	);
}

# Returns standard Enigma video codec: H264, MPEG4
# @returns arrayref - preference of video codecs (see applyFormats function)
sub getEnigmaVideo {
	my $self = shift;

	my @RC = (
		{ 'codec' => 'h264'  },
		{ 'codec' => 'mpeg4' },
		{ 'codec' => 'mpeg2video' },
	);
	return \@RC;
}

# Returns standard Enigma audio codec: AC3, AAC
# @returns arrayref - preference of audio codecs (see applyFormats function)
sub getEnigmaAudio {
	my $self = shift;

	my @RC = (
		{ 'codec' => 'ac3' },
		{ 'codec' => 'dts' },
		{ 'codec' => 'aac' },
		{ 'codec' => 'mp2' },
		{ 'codec' => 'wav' },
	);
	return \@RC;
}

# Returns standard Enigma subtitles codec: SRT
# @returns arrayref - preference of subtitle codecs (see applyFormats function)
sub getEnigmaSubtitles {
	my $self = shift;

	my @RC = (
		{ 'codec' => 'srt' },
	);
	return \@RC;
}

# Returns true when description is compatible with Enigma devices.
# @param $desc - hashref - description of file
# @returns boolean - whether file is compatible or not
sub isEnigmaCompatible {
	my $self = shift;
	my $desc = shift;

	return $self->isCompatible($desc, $self->getEnigmaVideo(), $self->getEnigmaAudio(), $self->getEnigmaSubtitles());
}

# Returns true when description is compatible with given codecs. 
# Subtitles are not checked yet.
# @param $desc            - hashref  - description of file
# @param $videoFormats    - arrayref - list of compatible video codecs
# @param $audioFormats    - arrayref - list of compatible audio codecs
# @param $subtitleFormats - arrayref - list of compatible subtitle codecs
# @returns boolean - whether file is compatible or not
sub isCompatible {
	my $self = shift;
	my $desc = shift;
	my $videoFormats = shift;
	my $audioFormats = shift;
	my $subtitleFormats = shift;
	my ($stream, $codec);

	return 0 if !$self->isVideoCompatible($desc, $videoFormats);
	return 0 if !$self->isAudioCompatible($desc, $audioFormats);

	return $self->isSubtitleCompatible($desc, $subtitleFormats);
}

# Returns true when description is compatible with given video codecs. 
# @param $desc            - hashref  - description of file
# @param $videoFormats    - arrayref - list of compatible video codecs
# @returns boolean - whether file is compatible or not
sub isVideoCompatible {
	my $self = shift;
	my $desc = shift;
	my $videoFormats = shift;
	my ($stream, $codec);

	# check video codecs (all streams must be OK)
	foreach $stream (keys(%{$desc->{video}})) {
		my $rc = 0;
		foreach $codec (@{$videoFormats}) {
			if ($codec->{codec} eq $desc->{video}->{$stream}->{codec_name}) {
				if (!$codec->{'profile'} || ($codec->{'profile'} eq $desc->{video}->{$stream}->{'profile'})) {
					$rc = 1;
				}
			}
		}
		return 0 if !$rc;
	}

	return 1;
}

# Returns true when description is compatible with given audio codecs. 
# @param $desc            - hashref  - description of file
# @param $audioFormats    - arrayref - list of compatible audio codecs
# @returns boolean - whether file is compatible or not
sub isAudioCompatible {
	my $self = shift;
	my $desc = shift;
	my $audioFormats = shift;
	my ($stream, $codec);

	# check audio codecs (alle streams must be ok)
	foreach $stream (keys(%{$desc->{audio}})) {
		my $rc = 0;
		foreach $codec (@{$audioFormats}) {
			if ($codec->{codec} eq $desc->{audio}->{$stream}->{codec_name}) {
				if (!$codec->{'profile'} || ($codec->{'profile'} eq $desc->{audio}->{$stream}->{'profile'})) {
					$rc = 1;
				}
			}
		}
		return 0 if !$rc;
	}

	return 1;
}

# Returns true when description is compatible with given subtitles codecs. 
# Subtitles are not checked yet. (Always returns true)
# @param $desc            - hashref  - description of file
# @param $subtitleFormats - arrayref - list of compatible subtitle codecs
# @returns boolean - whether file is compatible or not
sub isSubtitleCompatible {
	my $self = shift;
	my $desc = shift;
	my $subtitleFormats = shift;
	my ($stream, $codec);
	my $rc = 0;

	return 1;
}

# Applies the given codecs onto the description.
#
# The target codecs describe properties of the codec only, not specifics of a stream. This
# means that e.g. language settings will be ignored in codecs. If multiple codecs are given
# for a stream type then they describe a preference (e.g. AC3 over AAC if available). The lower
# priority shall be used only when higher profiles cannot be applied without conversion.
#
# For specifics see getApple* and getEnigma* funtions
#
# @param $description     - hashref - description of file (see analyze function)
# @param $videoFormat     - arrayref - description of video codec
#	(
#		0 => [ 'codec' => <codec> ],
#		1 => [ 'codec' => <codec> ],
#   )
# @param $audioFormat     - arrayref - description of audio codec
#	(
#		0 => [ 'codec' => <codec> ],
#		1 => [ 'codec' => <codec> ],
#   )
# @param $subtitlesFormat - arrayref - description of subtitles codec
#	(
#		0 => [ 'codec' => <codec> ],
#		1 => [ 'codec' => <codec> ],
#   )
# @returns hashref - description of target file (see analyze function)
sub applyFormats {
	my $self = shift;
	my $description = shift;
	my $videoFormat = shift;
	my $audioFormat = shift;
	my $subtitlesFormat = shift;

	# Make a complete copy before adjusting codecs
	my $rc = $self->copyHash($description);
	$self->applyBestCodec($rc->{video}, $videoFormat) if !$self->isVideoCompatible($description, $videoFormat);
	$self->applyBestCodec($rc->{audio}, $audioFormat) if !$self->isAudioCompatible($description, $audioFormat);
	$self->applyBestCodec($rc->{subtitle}, $subtitlesFormat) if !$self->isSubtitleCompatible($description, $subtitlesFormat);
	return $rc;
}

# Applies the best codec onto the given description.
# The new codecs are given in order of priority/quality. That means that a codec is replaced only when 
# existing codec is not mentioned as new codec. Otherwise the codec will be replaced.
# @param $desc   - hashref  - description of stream (video, audio, subtitle)
# @param $codecs - arrayref - codecs in order of priority
# @return NIL - $desc will be modified properly
sub applyBestCodec {
	my $self = shift;
	my $desc = shift;
	my $codecs = shift;

	my ($stream, $key, $codec, $bestCodec);
	foreach $stream (keys(%{$desc})) {
		my $found = 0;
		foreach $codec (@{$codecs}) {
			$bestCodec = $codec if !$bestCodec;
			if ($desc->{$stream}->{codec_name} eq $codec->{codec}) {
				if (!$codec->{profile} || ($codec->{profile} eq $desc->{$stream}->{profile})) {
					$found = 1;
					last;
				}
			}
		}
		if (!$found) {
			$desc->{$stream}->{codec_name} = $bestCodec->{codec};
			$desc->{$stream}->{profile} = $bestCodec->{profile};
		}
	}
}

# copies a hash.
sub copyHash {
	my $self = shift;
	my $orig = shift;
	my $rc = {};
	my $key;

	foreach $key (keys(%{$orig})) {
		my $value = $orig->{$key};
		my $type = ref($value);
		if ($type eq 'HASH') {
			$rc->{$key} = $self->copyHash($value);
		} elsif ($type eq 'ARRAY') {
			$rc->{$key} = $self->copyArray($value);
		} else {
			$rc->{$key} = $value;
		}
	}

	return $rc;
}

# Copies an array
sub copyArray {
	my $self = shift;
	my $orig = shift;
	my @RC = ();
	my $value;

	foreach $value (@{$orig}) {
		my $type = ref($value);
		if ($type eq 'HASH') {
			push(@RC, $self->copyHash($value));
		} elsif ($type eq 'ARRAY') {
			push(@RC, $self->copyArray($value));
		} else {
			push(@RC, $value);
		}
	}

	return \@RC;
}

# Computes the correct conversion for Apple.
# @param $fromDescription - hashref - see analyze function
# @param $options         - hashref - describes parameters (optional)
#         [
#            'defaultVideo' => <streamid>, (default is first video stream)
#            'defaultAudio' => <streamid> or <language> (ger/deu/eng/de/en - default is first audio stream),
#         ]
# @returns see convert function
sub getAppleConversion {
	my $self = shift;
	my $fromDescription = shift;
	my $options = shift;

	my $target = $self->applyAppleFormats($fromDescription);
	return $self->getConversion($fromDescription, $target, $options);
}


# Computes the correct conversion for Enigma.
# @param $fromDescription - hashref - see analyze function
# @param $options         - hashref - describes parameters (optional)
#         [
#            'defaultVideo' => <streamid>, (default is first video stream)
#            'defaultAudio' => <streamid> or <language> (ger/deu/eng/de/en - default is first audio stream),
#         ]
# @returns see convert function
sub getEnigmaConversion {
	my $self = shift;
	my $fromDescription = shift;
	my $options = shift;

	my $target = $self->applyEnigmaFormats($fromDescription);
	return $self->getConversion($fromDescription, $target, $options);
}

# Computes the correct conversion.
# @param $fromDescription   - hashref - description of source, see analyze function
# @param $targetDescription - hashref - description of destination, see analyze function
# @param $options           - hashref - describes parameters (optional)
#         [
#            'defaultVideo' => <streamid>, (no default)
#            'defaultAudio' => <streamid> or <language> (ger/deu/eng/de/en - default is first audio stream),
#         ]
# @returns arrayref - see convert function
sub getConversion {
	my $self     = shift;
	my $fromDescription = shift;
	my $targetDescription = shift;
	my $options  = shift;
	my @RC       = ();
	my @VIDEO    = ();
	my @AUDIO    = ();
	my @SUBTITLE = ();
	my ($stream);

	# video streams
	foreach $stream (keys(%{$fromDescription->{video}})) {
		my $srcStream = $fromDescription->{video}->{$stream};
		my $dstStream = exists $targetDescription->{video}->{$stream} ? $targetDescription->{video}->{$stream} : 0;
		if ($dstStream) {
			my $convert = $self->getVideoConversion($srcStream, $dstStream, $options);

			# Add stream
			$self->addConversion(\@VIDEO, $convert);
		}
	}

	# audio streams
	foreach $stream (keys(%{$fromDescription->{audio}})) {
		my $srcStream = $fromDescription->{audio}->{$stream};
		my $dstStream = exists $targetDescription->{audio}->{$stream} ? $targetDescription->{audio}->{$stream} : 0;
		if ($dstStream) {
			# Detect conversion
			my $convert = $self->getAudioConversion($srcStream, $dstStream, $options);

			# Add stream
			$self->addConversion(\@AUDIO, $convert);
		}
	}

	# subtitle streams
	foreach $stream (keys(%{$fromDescription->{subtitle}})) {
		my $srcStream = $fromDescription->{subtitle}->{$stream};
		my $dstStream = exists $targetDescription->{subtitle}->{$stream} ? $targetDescription->{subtitle}->{$stream} : 0;
		if ($dstStream) {
			# Detect conversion
			my $convert = $self->getSubtitleConversion($srcStream, $dstStream, $options);

			# Add stream
			$self->addConversion(\@SUBTITLE, $convert);
		}
	}

	push(@RC, @VIDEO);
	push(@RC, @AUDIO);
	push(@RC, @SUBTITLE);
	return \@RC;
}

# Determines the correct video conversion between two stream descriptions.
# @param $srcStream - hashref - description of source video stream
# @param $dstStream - hashref - description of destination video stream
# @param $options   - hashref - additional options
# @returns arrayref - description of conversion
sub getVideoConversion {
	my $self = shift;
	my $srcStream = shift;
	my $dstStream = shift;
	my $options = shift;

	my $convert = {
		'streamId'   => '0:'.$srcStream->{index},
		'streamType' => 'video',
		'language'   => $srcStream->{languageCode},
		'options'    => [],
		'default'    => 0,
	};

	# Detect conversion type
	if ($srcStream->{codec_name} eq $dstStream->{codec_name}) {
		$convert->{codec} = 'copy';
	} else {
		$convert->{codec} = $self->getCodecLib($dstStream->{codec_name});
	}

	# Some more options

	if (($convert->{streamId} eq $options->{defaultVideo}) || ($convert->{language} eq $options->{defaultVideo})) {
		$convert->{default} = 1;
	}
	return $convert;
}

# Determines the correct audio conversion between two stream descriptions.
# @param $srcStream - hashref - description of source audio stream
# @param $dstStream - hashref - description of destination audio stream
# @param $options   - hashref - additional options
# @returns arrayref - description of conversion
sub getAudioConversion {
	my $self = shift;
	my $srcStream = shift;
	my $dstStream = shift;
	my $options = shift;

	my $convert = {
		'streamId'   => '0:'.$srcStream->{index},
		'streamType' => 'audio',
		'language'   => $srcStream->{languageCode},
		'options'    => [],
		'default'    => 0,
	};

	# Detect conversion type
	if ($srcStream->{codec_name} eq $dstStream->{codec_name}) {
		$convert->{codec} = 'copy';
	} else {
		$convert->{codec} = $self->getCodecLib($dstStream->{codec_name});
	}

	# Some more options

	if (($convert->{streamId} eq $options->{defaultAudio}) || ($convert->{language} eq $options->{defaultAudio})) {
		$convert->{default} = 1;
	}
	return $convert;
}

# Determines the correct subtitle conversion between two stream descriptions.
# @param $srcStream - hashref - description of source subtitle stream
# @param $dstStream - hashref - description of destination subtitle stream
# @param $options   - hashref - additional options
# @returns arrayref - description of conversion
sub getSubtitleConversion {
	my $self = shift;
	my $srcStream = shift;
	my $dstStream = shift;
	my $options = shift;

	my $convert = {
		'streamId'   => '0:'.$srcStream->{index},
		'streamType' => 'subtitle',
		'language'   => $srcStream->{languageCode},
		'options'    => [],
		'default'    => 0,
	};

	# Detect conversion type
	if ($srcStream->{codec_name} eq $dstStream->{codec_name}) {
		$convert->{codec} = 'copy';
	} else {
		$convert->{codec} = $self->getCodecLib($dstStream->{codec_name});
	}

	# Some more options

	if (($convert->{streamId} eq $options->{defaultSubtitle}) || ($convert->{language} eq $options->{defaultSubtitle})) {
		$convert->{default} = 1;
	}
	return $convert;
}

# Adds the description to the array depending whether it is the default stream or not.
# @param $arr    - arrayref - return parameter
# @param $desc   - hashref  - description to be added to return parameter
# @param default - string   - streamId or languageCode of default description.
sub addConversion {
	my $self = shift;
	my $arr  = shift;
	my $desc = shift;


	if ($desc->{default}) {
		unshift(@{$arr}, $desc);
	} else {
		push(@{$arr}, $desc);
	}
}

# Returns the correct encoding parameter for a specific codec
sub getCodecLib {
	my $self = shift;
	my $codecName = shift;

	if ($ENCODERS->{$codecName}) {
		return $ENCODERS->{$codecName};
	}
	return $codecName;
}

# Build the ffmpeg conversion command from the conversion description
# @param $desc - hashref - the conversion description (see convert function)
# @returns array - parameters to ffmpeg binary
sub getConvertCommand {
	my $self = shift;
	my $desc = shift;
	# -metadata:s:a:0 language=eng
}

# Converts the given file.
# @param $srcPath - string - path of source file
# @param $options - arrayref - description of conversion
# [
#    0 => {
#        'streamId' => <stream-id>,
#        'streamType' => 'video'|'audio'|'subtitle',
#        'codec' => <codec>,
#        'language' => <language>,
#        'default' => 1|0,
#        'options' => {
#        },
#    },
#    1 => {
#        'streamId' => <stream-id>,
#        'streamType' => 'video'|'audio'|'subtitle',
#        'codec' => <codec>,
#        'language' => <language>,
#        'default' => 1|0,
#        'options' => {
#        },
#    },
# ]
# @param $dstPath - string - path of destination file (optional, default is to replace source file)
# @return 1 if successful
#
# Formats and options: see ffmpeg manpage for list of available codecs.
# 
sub convert {
	my $self     = shift;
	my $srcPath  = shift;
	my $options  = shift;
	my $dstPath  = shift;
}

1;

