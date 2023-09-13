/*

*/

CREATE OR REPLACE FUNCTION pg2l_get_filename(VARCHAR default '') RETURNS SETOF VARCHAR AS $$
	my $filepath;
	my $oraStatement 	= $_[0];
	my $line;
	my $retOID;

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
    };

    #get configuration
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
	
    foreach my $key (keys %pg2l_cfg)
    {
		my $get_query = sprintf("SHOW %s;",$key);
		#elog (INFO,$get_query);

       	#get configuration
        $sth = spi_query($get_query);

        while (defined (my $row = spi_fetchrow($sth))) {
            my $col = lc($key);
			$pg2l_cfg{$key} = $row->{$col};
			#elog (INFO,$pg2l_cfg{$key});
        }
		# checking configuration
	}

	my $system_cmd = sprintf ("%s %s %s %s %s %s %s %s %s '%s'", 	$pg2l_cfg{"PG2L.LOCATION_PERL"},
																	$pg2l_cfg{"PG2L.LOCATION_PRG"},
																	PG2L_CMD_EXPORT_FILE,
																	$pg2l_cfg{"PG2L.ORA_HOST"},
																	$pg2l_cfg{"PG2L.ORA_PORT"},
																	$pg2l_cfg{"PG2L.ORA_SID"},
																	$pg2l_cfg{"PG2L.ORA_ID"},
																	$pg2l_cfg{"PG2L.ORA_PWD"},
																	$pg2l_cfg{"PG2L.TARGET_PATH"},
																	$oraStatement
	);

	elog (INFO,"OID : $system_cmd ");
	open CMD,'-|',$system_cmd or die $@;
	while (defined($line=<CMD>)) {

		$line =~ s/^\s+|\s+$//g;
        my @ret = split('\^', $line);

        if ($ret[0] == PG2L_RET_SUCCESS)
        {
			return_next ($ret[1]);
        } elsif ($ret[0] == PG2L_RET_FAIL) {
            elog (ERROR,$ret[1]);
        }
	}
	close CMD;
    return undef;
$$ LANGUAGE plperlu;


/*

*/
CREATE OR REPLACE FUNCTION pg2l_get_oid(VARCHAR default '',INTEGER default 1) RETURNS oid AS $$
	use warnings ;
	use strict ;
	my $filepath;
	my $oraStatement 	= $_[0];
	my $delFileFlag		= $_[1];
	my $line;
	my $retOID;

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
	};

    #get configuration
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
	
    foreach my $key (keys %pg2l_cfg)
    {
		my $get_query = sprintf("SHOW %s;",$key);
		#elog (INFO,$get_query);

       	#get configuration
        my $sth = spi_query($get_query);

        while (defined (my $row = spi_fetchrow($sth))) {
            my $col = lc($key);
			$pg2l_cfg{$key} = $row->{$col};
			#elog (INFO,$pg2l_cfg{$key});
        }
		# checking configuration

	}

	my $system_cmd = sprintf ("%s %s %s %s %s %s %s %s %s '%s'", 	$pg2l_cfg{"PG2L.LOCATION_PERL"},
																	$pg2l_cfg{"PG2L.LOCATION_PRG"},
																	PG2L_CMD_EXPORT_FILE,
																	$pg2l_cfg{"PG2L.ORA_HOST"},
																	$pg2l_cfg{"PG2L.ORA_PORT"},
																	$pg2l_cfg{"PG2L.ORA_SID"},
																	$pg2l_cfg{"PG2L.ORA_ID"},
																	$pg2l_cfg{"PG2L.ORA_PWD"},
																	$pg2l_cfg{"PG2L.TARGET_PATH"},
																	$oraStatement
	);

	elog (INFO,"OID : $system_cmd ");
	open CMD,'-|',$system_cmd ;
	
	while (defined($line=<CMD>)) {
		$line =~ s/^\s+|\s+$//g;

		# checking return format;
		my @ret = split('\^', $line);

		if ($ret[0] == PG2L_RET_SUCCESS)
		{
			my $insert_lo = sprintf ("select (lo_import('%s')) as tmp_oid;", $ret[1]);
			elog (INFO,"OID : $insert_lo ");

			my $sth = spi_query($insert_lo);
			while (defined (my $row = spi_fetchrow($sth))) {
				# get oid
				$retOID = $row->{tmp_oid};
			}

			# check return

			# remove files
			if ($delFileFlag == 1)
			{
				my $delete_cmd  = sprintf("rm -rf %s", $ret[1]);
				my $rm_ret = system($delete_cmd);

				elog (INFO,"--------------------------------");
				elog (INFO,"line : $line");
				elog (INFO,"insert_lo : $insert_lo ");
				elog (INFO,"insert_lo : $retOID ");
				if ($rm_ret == 0)
				{
					elog (INFO,"temporary files $ret[1] removed");
				}
				elog (INFO,"--------------------------------");
			};
			close CMD;
			return $retOID;
		} elsif ($ret[0] == PG2L_RET_FAIL) {
			elog (ERROR,$ret[1]);
		}
	}
$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION pg2l_get_lob_length(VARCHAR default '',INTEGER default 1) RETURNS LONG AS $$
	use warnings ;
	use strict ;
	return 0;
$$ LANGUAGE plperlu;

/*

*/
CREATE OR REPLACE FUNCTION pg2l_get_oid_from_script(VARCHAR default '') RETURNS SETOF INTEGER AS $$
	use warnings ;
	use strict ;
	foreach (0..100) {
        return_next($_);
    }
    return undef;

$$ LANGUAGE plperlu;

/*
	input : 
*/
CREATE OR REPLACE FUNCTION pg2l_get_filename_from_script(VARCHAR default '') RETURNS SETOF INTEGER AS $$
	use warnings ;
	use strict ;
	foreach (0..100) {
        return_next($_);
    }
    return undef;
$$ LANGUAGE plperlu;


/*

*/
CREATE OR REPLACE FUNCTION pg2l_get_b1gb(VARCHAR default '') RETURNS SETOF INTEGER AS $$
	use warnings ;
	use strict ;
	foreach (0..100) {
        return_next($_);
    }
    return undef;
$$ LANGUAGE plperlu;


/*

*/

CREATE OR REPLACE FUNCTION pg2l_get_status(out no integer, out pg2lcfg text , out value text)
  RETURNS SETOF record
  LANGUAGE SQL AS
$func$
	SELECT * from (
		select 1 as no,'PG2L.LOCATION_PERL' as pg2lcfg, pg2l_get_conf('PG2L.LOCATION_PERL') as value
	UNION
		select 2 as no ,'PG2L.LOCATION_PRG' as pg2lcfg, pg2l_get_conf('PG2L.LOCATION_PRG') as value
	UNION
		select 3 as no ,'PG2L.ORA_HOST'     as pg2lcfg, pg2l_get_conf('PG2L.ORA_HOST') as value
	UNION
		select 4 as no ,'PG2L.ORA_PORT'     as pg2lcfg, pg2l_get_conf('PG2L.ORA_PORT') as value
	UNION
		select 5 as no ,'PG2L.ORA_SID'      as pg2lcfg , pg2l_get_conf('PG2L.ORA_SID') as value
	UNION
		select 6 as no ,'PG2L.ORA_ID'       as pg2lcfg, pg2l_get_conf('PG2L.ORA_ID') as value
	UNION
		select 7 as no ,'PG2L.ORA_PWD'      as pg2lcfg, pg2l_get_conf('PG2L.ORA_PWD') as value
	UNION
		select 8 as no ,'PG2L.TARGET_PATH'  as pg2lcfg, pg2l_get_conf('PG2L.TARGET_PATH') as value
	UNION  
		select 9,'Status Of Oracle'  as pg2lcfg, pg2l_ora_status() as values
	) order by no;
$func$;


CREATE OR REPLACE FUNCTION pg2l_ora_status() RETURNS SETOF VARCHAR AS $$
	use warnings ;
	use strict ;
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
    };

    #get configuration
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

    foreach my $key (keys %pg2l_cfg)
    {
        my $get_query = sprintf("SHOW %s;",$key);
		#elog (INFO,$get_query);

        #get configuration
        my $sth = spi_query($get_query);

        while (defined (my $row = spi_fetchrow($sth))) {
            my $col = lc($key);
            $pg2l_cfg{$key} = $row->{$col};
            #elog (INFO,$pg2l_cfg{$key});
        }
        # checking configuration
    }

    my $system_cmd = sprintf ("%s %s %s %s %s %s %s %s",    		$pg2l_cfg{"PG2L.LOCATION_PERL"},
                                                                    $pg2l_cfg{"PG2L.LOCATION_PRG"},
                                                                    PG2L_CMD_ORA_STATUS,
                                                                    $pg2l_cfg{"PG2L.ORA_HOST"},
                                                                    $pg2l_cfg{"PG2L.ORA_PORT"},
                                                                    $pg2l_cfg{"PG2L.ORA_SID"},
                                                                    $pg2l_cfg{"PG2L.ORA_ID"},
                                                                    $pg2l_cfg{"PG2L.ORA_PWD"}
    );

    elog (INFO,"OID : $system_cmd ");
    open CMD,'-|',$system_cmd or die $@;
    while (defined(my $line=<CMD>)) {
        $line =~ s/^\s+|\s+$//g;

        my @ret = split('\^', $line);

        if ($ret[0] == PG2L_RET_SUCCESS)
        {
    		return_next ("connection ok");
		} elsif ($ret[0] == PG2L_RET_FAIL)
		{
    		return_next  ("connection fail\n".$ret[1]);
		}
	}
    close CMD;
    return undef;

$$ LANGUAGE plperlu;

/*

*/
CREATE OR REPLACE FUNCTION pg2l_set_conf(VARCHAR default '',VARCHAR default '') RETURNS SETOF VARCHAR AS $$
	use warnings ;
	use strict ;

	#get configuration
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

	my $sth;
	my $key = $_[0];
	my $val	= $_[1];

	$key =~ s/^\s+|\s+$//g;
	$val =~ s/^\s+|\s+$//g;

	if ($key eq '' or $val eq '')
	{
		elog (ERROR,"pg2l_set_conf functions should be set 2 parameter which key and value");
		return undef;
	}

	# check validation of key
	my $check_exist_key = 0;
    foreach my $tmpkey (keys %pg2l_cfg)
    {
		if ($tmpkey eq $key)
		{
			$check_exist_key = 1;
			last;
		}
    }
	if ($check_exist_key == 0) 
	{
        elog(ERROR,"[pg2l - error] $key does not support. Please check list of configuration parameter ");
		exit;
	}

	# get current database name
    my $dbnm;
    $sth = spi_query("SELECT current_database();");
    while (defined (my $row = spi_fetchrow($sth))) {
    	# get dbname
        $dbnm = $row->{current_database};
    }

	# set configuration
	my $set_query = sprintf("ALTER DATABASE %s SET %s = '%s'; ",$dbnm,$key,$val);
	my $get_query = sprintf("SHOW %s;",$key);
	my $retSet;
	my $retGet;
	my $retLog = "";

	$retSet = spi_exec_query($set_query);

	if ($retSet->{status} eq 'SPI_OK_UTILITY')
	{
		$retLog = sprintf("configuration of %s has been set %s",$key,$val);
		elog(INFO,$retLog);
		return_next($val);
	}else
	{
		$retLog = sprintf("while try to exec statment it encournted errors [%s]",$set_query);
		elog(ERROR,$retLog);
		return undef;
	};

    return undef;
$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION pg2l_get_conf(VARCHAR default '') RETURNS SETOF VARCHAR AS $$
	use warnings ;
	use strict ;

    #get configuration
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

	my $sth;
	my $key = $_[0];
	$key =~ s/^\s+|\s+$//g;

	if ($key eq '')
    {
        elog (ERROR,"pg2l_get_conf functions should be set 1 parameter which key ");
        return undef;
    }

    # check validation of key
    my $check_exist_key = 0;
    foreach my $tmpkey (keys %pg2l_cfg)
    {
        if ($tmpkey eq $key)
        {
            $check_exist_key = 1;
            last;
        }
    }
    if ($check_exist_key == 0)
    {
        elog(ERROR,"$key does not support. Please check list of configuration parameter ");
        exit;
    }

    # get current database name
    my $dbnm;
    $sth = spi_query("SELECT current_database();");
    while (defined (my $row = spi_fetchrow($sth))) {
        # get dbname
        $dbnm = $row->{current_database};
    }

	my $get_query = sprintf("SHOW %s;",$key);

	$sth = spi_query($get_query);
    while (defined (my $row = spi_fetchrow($sth))) {
    	my $col = lc($key);
        return_next( $row->{$col} );
    }

    return undef;
$$ LANGUAGE plperlu;
