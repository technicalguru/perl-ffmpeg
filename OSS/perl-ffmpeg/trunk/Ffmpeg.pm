package Ffmpeg;
use strict;

my $FFMPEG_ROOT = '/usr/local/ffmpeg';
my $FFMPEG_BIN  = "$FFMPEG_ROOT/ffmpeg";
my $FFPROBE_BIN = "$FFMPEG_ROOT/ffprobe";

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
#    'subtitles' => [
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
		'subtitles' => {},
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
	foreach $stream (sort(keys(%{$desc->{subtitles}}))) {
		push(@RC, $self->getStreamString($desc->{subtitles}->{$stream}));
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
	foreach $stream (keys(%{$desc->{subtitles}})) {
		my $lang = $desc->{subtitles}->{$stream}->{'languageCode'};
		$lang = $desc->{subtitles}->{$stream}->{'languageId'} if !$lang;
		$lang = 'unknown' if !$lang;
		push(@SUBTITLES, "$lang (".$desc->{subtitles}->{$stream}->{codec_name}.")");
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

	return $self->applyFormats(
		$fromDescription.
		$self->getAppleVideo(),
		$self->getAppleAudio(),
		$self->getAppleSubtitles()
	);
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

	return $self->isCompatible($desc, $self->getAppleVideo(), $self->getAppleAudio(), $self->getAppleSubtitles());
}

# Applies codecs for Enigma.
# @param $fromDescription - hashref - source description (see analyze function)
# @returns hashref - target description (see analyze function)
sub applyEnigmaFormats {
	my $self = shift;
	my $fromDescription = shift;

	return $self->applyFormats(
		$fromDescription.
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
	my $rc = [];

	return $rc;
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
#            'defaultVideo' => <streamid>, (default is first video stream)
#            'defaultAudio' => <streamid> or <language> (ger/deu/eng/de/en - default is first audio stream),
#         ]
# @returns arrayref - see convert function
sub getConversion {
	my $self = shift;
	my $fromDescription = shift;
	my $targetDescription = shift;
	my $options = shift;
}

# Converts the given file.
# @param $srcPath - string - path of source file
# @param $options - arrayref - description of conversion
# [
#    0 => [
#        <stream-id>* => [
#            'codec' => <codec>,
#            'options' => [
#            ],
#        ],
#    ],
#    1 => [
#        <stream-id>* => [
#            'codec' => <codec>,
#            'options' => [
#            ],
#        ],
#    ],
#    2 => [
#        <stream-id>* => [
#            'codec' => <codec>,
#            'options' => [
#            ],
#        ],
#    ]
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

