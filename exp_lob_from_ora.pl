#!/usr/bin/perl 
use warnings ;
use strict ;
use Time::HiRes qw(time);
use DBI;
use Env;
use Data::Dumper;

$\="\n";
use constant {
        PG2L_CMD_EXPORT_FILE    => 0,
        PG2L_CMD_ORA_STATUS     => 1,
        PG2L_CMD_RUN_SCRIPT     => 2,
        PG2L_CMD_RUN_SQL        => 3,

# --------------------------------------
# PG2L RETURN MEG
# --------------------------------------
		PG2L_RET_SUCCESS		=> 100,
		PG2L_RET_FAIL			=> 901,
# --------------------------------------
# PG2L RETURN MEG
# --------------------------------------
		PG2L_MSG_DELIMITER		=> '^'
};

my %pg2l_cfg = (
        "PG2L.LOCATION_PERL"=> "",
        "PG2L.LOCATION_PRG" => "",
        "PG2L.ORA_SID"      => "",
        "PG2L.ORA_ID"       => "",
        "PG2L.ORA_HOST"     => "",
        "PG2L.ORA_PWD"      => "",
        "PG2L.ORA_PORT"     => "",
        "PG2L.TARGET_PATH"  => ""
);

my $cmd_type;
my $dbh;
my $ORA_STATEMENT;
my @sql_element;

my $idx_column			= 1;
my $idx_where_cond  	= 5;
my $where_statment  	= "";
my $sql_element_length 	= 0;

my $TARGET_FILENAME 	= "";
my $TBL_NAME 			= "";
my $file_extension 		= "";

sub main()
{
	getEnvVariable();

    if ($cmd_type eq PG2L_CMD_EXPORT_FILE) {
		fnc_preprocessing_exportFile();
    } elsif ($cmd_type eq  PG2L_CMD_ORA_STATUS )
    {
		fnc_check_ora_connection();
    } elsif ($cmd_type eq  PG2L_CMD_RUN_SCRIPT )
    {

    } elsif ($cmd_type eq  PG2L_CMD_RUN_SQL ){

    }
}

sub fnc_preprocessing_exportFile()
{
	@sql_element = split(' ', $ORA_STATEMENT);
	if ($sql_element[1] =~ /,/ or uc($sql_element[2]) ne 'FROM' )
	{
		print " This function support only one column for lob\n Please check sql statements";
		exit -1;
	}

#	if (uc($sql_element[4]) ne 'WHERE')
#	{
#		print " sql statement has wrong \n";
#		exit -1;
#	}

	$sql_element_length = scalar @sql_element - 1;
	if (defined $sql_element[4])
	{
		$where_statment  = join ' ', @sql_element[$idx_where_cond .. $sql_element_length];

	}else
	{
		$where_statment  = "none_where";
		print " sql statement has wrong or none where condition\n";
	}


	# Remove Special Character from Where Condition.
	my $foo = $where_statment;
	$foo =~ s/[^\p{PosixAlnum},]/ /g;
	my @where_cond = split(' ', $foo);

	foreach my $cond (@where_cond){
		$file_extension = $file_extension.$cond."_";
	}

	$TBL_NAME = $sql_element[3];

	my $dbHandle = new oraConnection(); 

	$dbHandle->exportFile();
	$dbh->disconnect();

	undef ($dbHandle);
}

sub fnc_check_ora_connection()
{
	my $dbHandle = new oraConnection(); 
}

sub getEnvVariable()
{
	# validation check and copy env variable into the local variable
	my $retVal = "";
	$cmd_type						= $ARGV[0];

	if ($cmd_type eq PG2L_CMD_EXPORT_FILE) {
    		$pg2l_cfg{"PG2L.ORA_HOST"}     	= $ARGV[1];
    		$pg2l_cfg{"PG2L.ORA_PORT"}     	= $ARGV[2];
			$pg2l_cfg{'PG2L.ORA_SID'}      	= $ARGV[3];
			$pg2l_cfg{"PG2L.ORA_ID"}       	= $ARGV[4];
    		$pg2l_cfg{"PG2L.ORA_PWD"}      	= $ARGV[5];
    		$pg2l_cfg{"PG2L.TARGET_PATH"}  	= $ARGV[6];
    		$ORA_STATEMENT 			  		= $ARGV[7];
	} elsif ($cmd_type eq  PG2L_CMD_ORA_STATUS )
	{
    		$pg2l_cfg{"PG2L.ORA_HOST"}     	= $ARGV[1];
    		$pg2l_cfg{"PG2L.ORA_PORT"}     	= $ARGV[2];
			$pg2l_cfg{'PG2L.ORA_SID'}      	= $ARGV[3];
			$pg2l_cfg{"PG2L.ORA_ID"}       	= $ARGV[4];
    		$pg2l_cfg{"PG2L.ORA_PWD"}      	= $ARGV[5];
    		$pg2l_cfg{"PG2L.TARGET_PATH"}  	= $ARGV[6];
	} elsif ($cmd_type eq  PG2L_CMD_RUN_SCRIPT )
	{

	} elsif ($cmd_type eq  PG2L_CMD_RUN_SQL ){

	}
}

sub trim {
  my @result = @_;
  foreach (@result) {
    s/^\s+//;          
    s/\s+$//;          
  }

  return wantarray ? @result : $result[0];
}

main();

package oraConnection;
use constant {
        PG2L_CMD_EXPORT_FILE    => 0,
        PG2L_CMD_ORA_STATUS     => 1,
        PG2L_CMD_RUN_SCRIPT     => 2,
        PG2L_CMD_RUN_SQL        => 3,

# --------------------------------------
# PG2L RETURN MEG
# --------------------------------------
        PG2L_RET_SUCCESS        => 100,
        PG2L_RET_FAIL           => 901,
# --------------------------------------
# PG2L RETURN MEG
# --------------------------------------
        PG2L_MSG_DELIMITER      => '^'
};

#sub handle_error {
#    my $message = shift;
#	my $code = shift;
#    #write error message wherever you want
#    print "[$code] the message is '$message'\n";
#    exit; #stop the program
#}

sub new()
{
#my %attrs = (RaiseError => 1, PrintError => 1, AutoCommit => 0, HandleError => \&handle_error);
    my $class = shift;
	my %attrs = (RaiseError => 1, PrintError => 0);
	my $ORACLE_URI = sprintf ("dbi:Oracle:host=%s;sid=%s;port=%s",	$pg2l_cfg{'PG2L.ORA_HOST'},
																	$pg2l_cfg{'PG2L.ORA_SID'},
																	$pg2l_cfg{'PG2L.ORA_PORT'});

	$dbh = eval {
		DBI->connect(	$ORACLE_URI, 
						$pg2l_cfg{'PG2L.ORA_ID'} , 
						$pg2l_cfg{'PG2L.ORA_PWD'} ,
						\%attrs
		);
	};

	if (!$dbh) {
		#say $dbh->get_info($GetInfoType{SQL_DBMS_NAME});
		#say $dbh->get_info($GetInfoType{SQL_DBMS_VER});
		my $retfmt = sprintf("%s%s[%s]%s", PG2L_RET_FAIL , PG2L_MSG_DELIMITER , $DBI::err, $DBI::errstr);
		print $retfmt;
		exit;
	}else
	{
    	my	$self = {_dbh => $dbh};
   		bless $self, $class;

		if ($cmd_type eq  PG2L_CMD_ORA_STATUS)
		{
			my $retfmt = sprintf("%s%s%s", PG2L_RET_SUCCESS , PG2L_MSG_DELIMITER , "connection ok");
			print $retfmt;
		}
   		return $self;
	}
}

sub getLengthOfLob()
{
	# Get length of LOB
	my $self = shift;
	my $sql = sprintf("SELECT dbms_lob.getlength(%s) FROM %s WHERE %s",$sql_element[1],$TBL_NAME,$where_statment);
	my $sth  = $self->{_dbh}->prepare($ORA_STATEMENT , { ora_auto_lob => 0 } );
	#print $sql;
}

sub exportFile()
{
	my $self = shift;

	# Query Rewirte
	my	$sqlrewrite;
	if (defined $sql_element[4])
	{
		$sqlrewrite  = sprintf("SELECT dbms_lob.getlength(%s),%s FROM %s WHERE %s ",$sql_element[1] , $sql_element[1],$TBL_NAME,$where_statment);
	}else
	{
		$sqlrewrite  = sprintf("SELECT dbms_lob.getlength(%s),%s FROM %s ",$sql_element[1] , $sql_element[1],$TBL_NAME);
	}

	my $sth	= $self->{_dbh}->prepare($sqlrewrite , { ora_auto_lob => 0 } );

	$sth->execute( );
	my $seq = 0;
	while (	my @row = $sth->fetchrow_array()) {
		my ($lob_len, $lob) = @row;
		my $chunk_size 	= 32767;  
		my $amount     	= 32767;
		my $offset 		= 1;   # Offsets start at 1, not 0

		$seq++;
		my $tmp_extension = $file_extension . time().'_'.$seq;
		$TARGET_FILENAME = $sql_element[3].".".$tmp_extension;

		# Create file :
		my $filepath = sprintf("%s/%s",$pg2l_cfg{'PG2L.TARGET_PATH'} , $TARGET_FILENAME);
		open (FILE, ">:raw", $filepath);
		binmode FILE;

		while ($offset <= $lob_len)
		{
			my $data = $dbh->ora_lob_read( $lob,$offset, $chunk_size) ;

			syswrite FILE,$data,length($data);
			$offset = $offset + $amount ;
			$data = undef;
		}
		my $absPath = $pg2l_cfg{'PG2L.TARGET_PATH'}."/".$TARGET_FILENAME;
		$absPath =~ s/\/\//\//g;

		# setting return format
		my $retfmt = sprintf("%s%s%s", PG2L_RET_SUCCESS , PG2L_MSG_DELIMITER , $pg2l_cfg{'PG2L.TARGET_PATH'}."/".$TARGET_FILENAME);
		print  $retfmt;

		undef $lob;
		close FILE;
	}
	$sth->finish();
#	print ("done\n");
}

