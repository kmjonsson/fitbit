
package Fitbit;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
#use Data::Dumper;
use JSON;

sub new {
	my($class) = shift;
	my($opts)  = shift // {};

	my $self  = {
		'cookiefile' => $opts->{cookiefile} // 'cookies.txt',
	};
	bless ($self, $class);
	$self->{ua} = LWP::UserAgent->new;
	$self->{ua}->agent("Mozilla/10");
	$self->{jar} = HTTP::Cookies->new(
		file => $self->{cookiefile},
		autosave => 1,
	);
	$self->{ua}->cookie_jar($self->{jar});
	return $self;
}


sub login {
	my($self,$email,$password) = @_;

	my($rclp,$login_page) = $self->get("https://www.fitbit.com/login");

	return unless $rclp eq '200 OK'; 

	my $login_data = {
		email => $email,
		password => $password,
		login => 'Log in',
		includeWorkflow=>'',
		redirect=>'',
		switchToNonSecureOnRedirect=>'',
		disableThirdPartyLogin=>'false',
	};

	foreach my $l ( split(/</,$login_page) ) {
		if($l =~ /input type=\"hidden\" name=\"(_sourcePage|__fp)\" value=\"([^\"]+)\" \/>/) {
			$login_data->{$1} = $2;
		}
	}

	my($rc) = $self->post('https://www.fitbit.com/login',$login_data);

	return unless $rc eq '302 Found';

	return $self;
}

sub csrfToken {
	my($self) = @_;
	my($csrfToken) = grep { /^Set-Cookie3: u=/ } split(/\n/,$self->{jar}->as_string);
	$csrfToken = (split(/\|/,$csrfToken))[2];
	return $csrfToken;
}

sub get {
	my($self,$url) = @_;
	# Pass request to the user agent and get a response back
	my $res = $self->{ua}->request(GET $url);
	# Check the outcome of the response
	if ($res->is_success) {
		return ($res->status_line,$res->content);
	}
	return ($res->status_line);
}


sub post {
	my($self,$url,$data) = @_;
	# Pass request to the user agent and get a response back
	my $res = $self->{ua}->request(POST $url, [ %$data ]);

	# Check the outcome of the response
	if ($res->is_success) {
		return ($res->status_line,$res->content);
	}
	return ($res->status_line);;
}

my $types = {
	'active_minutes'  => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"dataTypes":"active-minutes" ,"date":"#date#"},"method":"getTileData"}]}',
	'calories_burned' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"dataTypes":"calories-burned" ,"date":"#date#"},"method":"getTileData"}]}',
	'distance' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"dataTypes":"distance" ,"date":"#date#"},"method":"getTileData"}]}',
	'floors' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"dataTypes":"floors" ,"date":"#date#"},"method":"getTileData"}]}',
	'steps' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"dataTypes":"steps" ,"date":"#date#"},"method":"getTileData"}]}',

	'id_active_minutes' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"date":"#date#" ,"dataTypes":"active-minutes"},"method":"getIntradayData"}]}',
	'id_calories_burned' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"date":"#date#" ,"dataTypes":"calories-burned"},"method":"getIntradayData"}]}',
	'id_distance' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"date":"#date#" ,"dataTypes":"distance"},"method":"getIntradayData"}]}',
	'id_floors' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"date":"#date#" ,"dataTypes":"floors"},"method":"getIntradayData"}]}',
	'id_steps' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"date":"#date#" ,"dataTypes":"steps"},"method":"getIntradayData"}]}',

	'sleep' => '{"template":"/ajaxTemplate.jsp","serviceCalls":[{"name":"activityTileData","args":{"dateFrom":"#dateFrom#" ,"dateTo":"#dateTo#"},"method":"getSleepTileData"}]}',
};

sub _fetch {
	my($self,$type,$param) = @_;
	my $req = $types->{$type};
	foreach my $k (keys %$param) {
		$req =~ s,#$k#,$param->{$k},g;
	}
	my $fb = Fitbit->new();
	my($csrfToken) = $fb->csrfToken();

	return unless defined $csrfToken;
	return unless length $csrfToken > 10;

	my $data = {
		csrfToken=>$csrfToken,
		request => $req,
	};

	my($rc,$content) = $fb->post('https://www.fitbit.com/ajaxapi',$data);

	return unless $rc eq '200 OK';

	$content =~ s,^\s+,,m;
	$content =~ s,\s+$,,m;

	my $d = eval { decode_json($content); };
	return $d;
}

sub sleep {
	my($self,$datefrom,$dateto) = @_;
	return $self->_fetch('sleep',{ dateFrom => $datefrom, dateTo => $dateto });
}
sub active_minutes {
	my($self,$date) = @_;
	return $self->_fetch('active_minutes',{ date => $date });
}
sub calories_burned {
	my($self,$date) = @_;
	return $self->_fetch('calories_burned',{ date => $date });
}
sub distance {
	my($self,$date) = @_;
	return $self->_fetch('distance',{ date => $date });
}
sub floors {
	my($self,$date) = @_;
	return $self->_fetch('floors',{ date => $date });
}
sub steps {
	my($self,$date) = @_;
	return $self->_fetch('steps',{ date => $date });
}
sub id_active_minutes {
	my($self,$date) = @_;
	return $self->_fetch('id_active_minutes',{ date => $date });
}
sub id_calories_burned {
	my($self,$date) = @_;
	return $self->_fetch('id_calories_burned',{ date => $date });
}
sub id_distance {
	my($self,$date) = @_;
	return $self->_fetch('id_distance',{ date => $date });
}
sub id_floors {
	my($self,$date) = @_;
	return $self->_fetch('id_floors',{ date => $date });
}
sub id_steps {
	my($self,$date) = @_;
	return $self->_fetch('id_steps',{ date => $date });
}

1;
