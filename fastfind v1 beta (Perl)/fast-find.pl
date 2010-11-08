#!/usr/bin/perl
# Name: Fast-Find
# Author: Alwyn Malachi Berkeley <malachix@malachix.com>
# Created: 12-16-2005 11:36:47 EST
# Last Modified: 1-6-2005 21:20:26 EST
# 
# Description:
# A simple application engineered to dig url's in order to determine 
# what 3 letter url's are still available for purchase.
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; only version 2 of the License.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#       02111-1307, USA.

use 5.008;
#use warnings;
use threads;

sub decipherParameters {
# interprets parameters sent to the program
	
	# set some basic default variables
	$slrIsFinishSet = "false";
	$slrIsExtensionSet = "false";
	$slrIsStartSet = "false";
	$slrIsTimelessSet = "false";
	$slrIsVerbose = "false";
	$slrCustomEnd = "";
	$slrOutputFile = "";
	@arrExtensions = ();
	
	my $slrGotoParam = ""; # helps delegate work to code blocks
	my $slrBuffer2 = 0; # tells where domains should be placed in list
	foreach $slrBuffer(@ARGV) {
		# check for extension parameters
		if ($slrBuffer eq "-e" or $slrBuffer eq "--extensions" or $slrGotoParam eq "extension") {
			if ($slrGotoParam eq "") {
				$slrGotoParam = "extension";
				$slrIsExtensionSet = "true";
			} else {
				# reset the var for use again (if needed)
				if ($slrBuffer eq "-f" or $slrBuffer eq "--finish" or $slrBuffer eq "-h" or $slrBuffer eq "--help" or $slrBuffer eq "-e" or $slrBuffer eq "--extensions" or $slrBuffer eq "-s" or $slrBuffer eq "--start" or $slrBuffer eq "-t" or $slrBuffer eq "--timeless" or $slrBuffer eq "-v" or $slrBuffer eq "--verbose" or $slrBuffer eq "-V" or $slrBuffer eq "--version" or $slrBuffer eq $ARGV[(scalar(@ARGV) - 1)]) {
					$slrGotoParam = "";
				} else {
					# add extension to extension list
					$arrExtensions[$slrBuffer2] = "." . $slrBuffer;
					$slrBuffer2++;
				}
			}

			# if the parameter is a command or filename let this
			# iteration do it's work, otherwise goto next iteration
			# and let the extensions continue being deciphered
			if ($slrBuffer ne $ARGV[(scalar(@ARGV) - 1)] and $slrGotoParam ne "") {
				next;
			}
		}

		# check for finish sequence
		if ($slrBuffer eq "-f" or $slrBuffer eq "--finish" or $slrGotoParam eq "finish") {
			if ($slrGotoParam eq "") {
				$slrGotoParam = "finish";
				$slrIsFinishSet = "true";
			} else {
				# extract three letter sequence
				$slrEndX = substr($slrBuffer, 4, 1);
				$slrEndY = substr($slrBuffer, 5, 1);
				$slrEndZ = substr($slrBuffer, 6, 1);

				# creating domain string to end on (no ending)
				$slrCustomEnd = "www." . $slrEndX . $slrEndY . $slrEndZ;

				# check that sequence is valid
				validAlphanumeric($slrEndX) || die "Error: First digit of finish sequence is incorrect.";
				validAlphanumeric($slrEndY) || die "Error: Second digit of finish sequence is incorrect.";
				validAlphanumeric($slrEndZ) || die "Error: Third digit of finish sequence is incorrect.";
								
				# reset the var for use again later
				$slrGotoParam = "";
			}
			next;
		}
		
		# check if program should display the help dialog and exit
		if ($slrBuffer eq "-h" or $slrBuffer eq "--help") {
			print "Usage: fastfind [OPTION]... [FILE]...\n";
			print "Find unregistered three letter domains (only .com's searched for by default).\n\n";
			print "-f, --finish [domain]              ends the program at the domain given.\n";
			print "-h, --help                         displays the help dialog and then exits.\n";
			print "-e, --extensions [extension ...]   searches for only specified extensions.\n";
			print "-s, --start [domain]               starts the program at the domain given.\n";
			print "-t, --timeless                     report the output without the timestamps.\n";
			print "-v, --verbose                      run program in verbose mode.\n";
			print "-V, --version                      display version information and then exits.\n";
			print "\nWhen filename is given the output goes into \"available.txt\" by default.\n";
			print "\nReport bugs to <malachix\@malachix.com>.\n";
			exit;
		}
		
		# check for start sequence
		if ($slrBuffer eq "-s" or $slrBuffer eq "--start" or $slrGotoParam eq "start") {
			if ($slrGotoParam eq "") {
				$slrGotoParam = "start";
				$slrIsStartSet = "true";
			} else {
				# extract three letter sequence
				$slrStartX = substr($slrBuffer, 4, 1);
				$slrStartY = substr($slrBuffer, 5, 1);
				$slrStartZ = substr($slrBuffer, 6, 1);
								
				# check that sequence is valid
				validAlphanumeric($slrStartX) || die "Error: First digit of start sequence is incorrect.";
				validAlphanumeric($slrStartY) || die "Error: Second digit of start sequence is incorrect.";
				validAlphanumeric($slrStartZ) || die "Error: Third digit of start sequence is incorrect.";

				# convert
				convertAlphanumerics();
				
				# reset the var for use again later
				$slrGotoParam = "";
			}
			next;
		}

		# check whether timestamps should be in the output file
		if ($slrBuffer eq "-t" or $slrBuffer eq "--timeless") {
			$slrIsTimelessSet = "true";
			next;
		}

		# check whether the program should be talkative
		if ($slrBuffer eq "-v" or $slrBuffer eq "--verbose") {
			$slrIsVerbose = "true";
			next;
		}

		# check if the program should display version and exit
		if ($slrBuffer eq "-V" or $slrBuffer eq "--version") {
			print "fastfind v0.1.0 beta\n";
			print "Written by Alwyn Malachi Berkeley.\n\n";
			print "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n";
			exit;
		}

		# check if it is the filename to leave output within
		if ($slrBuffer eq $ARGV[(scalar(@ARGV) - 1)]) {
			$slrOutputFile = $slrBuffer;
		}
	}

	# if the output file hasn't been stated then use the default
	if ($slrOutputFile eq "") {
		$slrOutputFile = "available.txt";
	}

	# add the extension to the custom end string (if needed)
	foreach $slrBuffer(@ARGV) {
		if ($slrBuffer eq "-e" or $slrBuffer eq "--extensions") {
			$slrCustomEnd .= $arrExtensions[0];
		}
	}
}

sub welcome {
# just a welcome message

	print "This program is going to find all 3 letter domains still available for purchase and place the output in an output file called \"$slrOutputFile\" upon completion.\n\n";
}

sub appendFile {
# appends text to a file
	my($slrFileNameBuffer, $slrAppendedTextBuffer) = @_;

	open(FILEHANDLE, ">>$slrFileNameBuffer");
		print FILEHANDLE $slrAppendedTextBuffer;
	close(FILEHANDLE);
}

sub digURL {
# dig domain to see if it exists
# if it exists return 1(true), otherwise return 0(false)
	my($slrUrlBuffer) = @_;

	my $slrResult = `dig $slrUrlBuffer`;

	if (index($slrResult, "status: NXDOMAIN") > 0) {
		return 0;
	} else {
		return 1;
	}
}

sub validAlphanumeric {
# if the digit passed to this subroutine is a valid for use with the program
# then return 1(true), otherwise return 0(false)
	my($slrDigitBuffer) = @_;

	if (ord($slrDigitBuffer) > 47 && ord($slrDigitBuffer) < 58) {
		return 1;
	} elsif (ord($slrDigitBuffer) == 45) {
		return 1;
	} elsif (ord($slrDigitBuffer) > 96 && ord($slrDigitBuffer) < 123) {
		return 1;
	} else {
		return 0;
	}
}

sub convertAlphanumerics {
# converts ascii letters to the corresponding number on the program's
# custom internal ascii chart
	
	my $slrSpotBuffer = 0;
	for ($slrBuffer = 0; $slrBuffer < 3; $slrBuffer++) {
		if ($slrBuffer == 0) {
			$slrSpotBuffer = \$slrStartX;
		} elsif ($slrBuffer == 1) {
			$slrSpotBuffer = \$slrStartY;
		} elsif ($slrBuffer == 2) {
			$slrSpotBuffer = \$slrStartZ;
		}
		
		if (ord($$slrSpotBuffer) > 47 && ord($$slrSpotBuffer) < 58) {
			$$slrSpotBuffer = ord($$slrSpotBuffer) - 48;
		} elsif (ord($$slrSpotBuffer) == 45) {
			$$slrSpotBuffer = 10;
		} elsif (ord($$slrSpotBuffer) > 96 && ord($$slrSpotBuffer) < 123) {
			$$slrSpotBuffer = ord($$slrSpotBuffer) - 86;
		}
	}
}

sub getCustomAscii {
# simply returns 0-9, a-z, and hyphen depending on the number passed(0-36)
	my($slrIndex) = @_;

	if ($slrIndex > -1 && $slrIndex < 10) {
		$slrIndex = chr($slrIndex + 48);
		return $slrIndex;
	} elsif ($slrIndex == 10) {
		return '-';
	} else {
		$slrIndex = chr($slrIndex + 86);
		return $slrIndex;
	}
}

sub prelimQuestions {
# ask a few preliminary questions for the program

if ($slrIsStartSet ne "true") {
	# where do we start from?
	print "Where would you like to start?\n";
	print "1) From the beginning\n";
	print "2) Custom spot\n";

	$slrBuffer = "";
	do {
		print "Type a number:  "; chomp($slrBuffer = <STDIN>);
	} until ($slrBuffer eq '1' || $slrBuffer eq '2');
	
	if ($slrBuffer eq '1') {
		# default beginning spots
		$slrStartX = 0;
		$slrStartY = 0;
		$slrStartZ = 0;
	} elsif ($slrBuffer eq '2') {
		# finding the custom spots to start from
		do {
			print "What digit should the first spot be?  ";
			chomp($slrStartX = <STDIN>);
		} until (validAlphanumeric($slrStartX));
		
		do {
			print "What digit should the second spot be?  ";
			chomp($slrStartY = <STDIN>);
		} until (validAlphanumeric($slrStartY));

		do {
			print "What digit should the third spot be?  ";
			chomp($slrStartZ = <STDIN>);
		} until (validAlphanumeric($slrStartZ));

		# user's choices are valid but they still need to be converted
		# to the program's internal ascii chart in order for the
		# program to use them
		convertAlphanumerics();
	}
}

if ($slrIsFinishSet ne "true") {
	# where do we end?
	print "\nWhere would you like to end at?\n";
	print "1) At the last possible combination\n";
	print "2) Custom spot\n";
	
	$slrBuffer = "";
	do {
		print "Type a number:  "; chomp($slrBuffer = <STDIN>);
	} until ($slrBuffer eq '1' || $slrBuffer eq '2');

	if ($slrBuffer eq '1') {
		$slrCustomEnd = "";
	} elsif ($slrBuffer eq '2') {
		# finding the custom spot to end at
		my $slrEndX = "";
		do {
			print "What digit should the first spot be?  ";
			chomp($slrEndX = <STDIN>);
		} until (validAlphanumeric($slrEndX));
		
		my $slrEndY = "";
		do {
			print "What digit should the second spot be?  ";
			chomp($slrEndY = <STDIN>);
		} until (validAlphanumeric($slrEndY));

		my $slrEndZ = "";
		do {
			print "What digit should the third spot be?  ";
			chomp($slrEndZ = <STDIN>);
		} until (validAlphanumeric($slrEndZ));

		my $slrEndExtension = "";
		do {
			print "What extension should it end with (Without the \".\" prefix)?  ";
			chomp($slrEndExtension = <STDIN>);

			# check input
			if (substr($slrEndExtension, 0, 1) eq ".") {
				print "*** Type the extension again without the dot prefix please. ***\n";
			} elsif ($slrEndExtension eq "") {
				print "*** You left the input blank, please type an extension. ***\n";
			}
		} until (substr($slrEndExtension, 0, 1) ne "." && $slrEndExtension ne "");

		# creating domain string to end on
		$slrCustomEnd = "www." . $slrEndX . $slrEndY . $slrEndZ . "." . $slrEndExtension;
	}
}

if ($slrIsExtensionSet ne "true") {
	# which extensions do we check?
	print "\nWhich extensions should I search for?\n";
	print "1) .com's\n";
	print "2) .com's and .net's\n";
	print "3) Other (You specify)\n";

	$slrBuffer = "";
	do {
		print "Type a number:  "; chomp($slrBuffer = <STDIN>);
	} until ($slrBuffer eq '1' || $slrBuffer eq '2');

	if ($slrBuffer == 1) { # choice 1
		$arrExtensions[0] = ".com";
	} elsif ($slrBuffer == 2) { # choice 2
		$arrExtensions[0] = ".com";
		$arrExtensions[1] = ".net";
	} elsif ($slrBuffer == 3) { # choice 3
		# quick instructions to user
		print "\nType the extension(s) you would like to look for, (Without the \".\" prefix).";
		print "\nType in \"done\" to stop adding domains.\n\n";
		
		# finding extensions to use
		$slrBuffer = "";
		my $slrBuffer2 = 0;
		do {
			do {				
				# gather input
				print "Type domain extension:  ";
				chomp($slrBuffer = <STDIN>);

				# check input
				if ($slrBuffer eq "done" && $slrBuffer2 == 0) {
					print "*** You cannot finish without entering at least one domain extension. ***\n";
				} elsif (substr($slrBuffer, 0, 1) eq ".") {
					print "*** Type the extension again without the dot prefix please. ***\n";
				} elsif ($slrBuffer eq "") {
					print "*** You left the input blank, please type an extension. ***\n";
				}
			} while ($slrBuffer eq "done" && $slrBuffer2 == 0 || substr($slrBuffer, 0, 1) eq "." || $slrBuffer eq "");
			
			# add extension choice
			if ($slrBuffer ne "done") {
				$arrExtensions[$slrBuffer2] = "." . $slrBuffer;
				$slrBuffer2++;
			}
		} while ($slrBuffer ne "done");
	}
}

	print "\n"; # formatting
}

sub createList {
# simple subroutine that creates the list of domains the program will dig

	my $slrWorldWideWeb = "www.";
	my @arrBuffer2 = ();
	my @arrBuffer3 = ();
	
	for (my $x = $slrStartX; $x < 37; $x++) {
		# don't do any domains beginning with a hyphen
		if ($x == 10) {
			next;
		}
	
		# concantenate the "www."
		$slrBuffer = $slrWorldWideWeb;
	
		# getting first digit, www.x
		$slrBuffer .= getCustomAscii($x);

		# getting all possible second digit patterns
		for (my $y = $slrStartY; $y < 37; $y++) {
			# www.xy
			$arrBuffer2[$y] = $slrBuffer;
			$arrBuffer2[$y] .= getCustomAscii($y);
			
			# reset for next set of iterations
			if ($slrStartY != 0) {
				$slrStartY = 0;
			}
			
			# getting all possible third digit patterns
			for (my $z = $slrStartZ; $z < 37; $z++) {
				# don't add domains ending with a hyphen
				if ($z == 10) {
					next;
				}
			
				# www.xyz
				$arrBuffer3[$z] = $arrBuffer2[$y];
				$arrBuffer3[$z] .= getCustomAscii($z);

				# concantenate endings, add them to the list
				foreach $slrBuffer (@arrExtensions) {
					# add latest domain combination
					push(@arrDomainList, $arrBuffer3[$z] . $slrBuffer);
				}
				
				# reset for next set of iterations
				if ($slrStartZ != 0) {
					$slrStartZ = 0;
				}
			}
		}
	}
}

sub checkDomainExists {
# checks if a domain exists and reports it to the console/shell
	my($slrDomainUrl) = @_;

	# if the domain is still available...
	if (digURL($slrDomainUrl) == 0) {
		# ...save it
		appendFile($slrOutputFile, $slrDomainUrl);

		# for verbose mode
		if ($slrIsVerbose eq "true") {
			print "$slrDomainUrl...not taken\n";
		}
	} else {
		# for verbose mode
		if ($slrIsVerbose eq "true") {
			print "$slrDomainUrl...taken\n";
		}
	}
}

sub queueJobs {
# queue the jobs that check domain existence
	my($slrStartFromIndex) = @_;
	
	for ($slrIndex = $slrStartFromIndex; $slrIndex < $slrStartFromIndex + 10; $slrIndex++) {
		if (defined($arrDomainList[$slrIndex])) {
			if ($slrIndex == $slrStartFromIndex) {
				$slrThread1 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 1) {
				$slrThread2 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 2) {
				$slrThread3 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 3) {
				$slrThread4 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 4) {
				$slrThread5 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 5) {
				$slrThread6 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 6) {
				$slrThread7 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 7) {
				$slrThread8 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 8) {
				$slrThread9 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			} elsif ($slrIndex == $slrStartFromIndex + 9) {
				$slrThread10 = threads->new(\&checkDomainExists, $arrDomainList[$slrIndex]);
			}
		}
	}
}

sub joinJobs {
# joins together all the running threads

	my $slrThreadBuffer;
	foreach $slrThreadBuffer(threads->list()) {
		if ($slrThreadBuffer->tid == $slrThread1->tid) {
			$slrThread1->join();
		} elsif ($slrThreadBuffer->tid == $slrThread2->tid) {
			$slrThread2->join();
		} elsif ($slrThreadBuffer->tid == $slrThread3->tid) {
			$slrThread3->join();
		} elsif ($slrThreadBuffer->tid == $slrThread4->tid) {
			$slrThread4->join();
		} elsif ($slrThreadBuffer->tid == $slrThread5->tid) {
			$slrThread5->join();
		} elsif ($slrThreadBuffer->tid == $slrThread6->tid) {
			$slrThread6->join();
		} elsif ($slrThreadBuffer->tid == $slrThread7->tid) {
			$slrThread7->join();
		} elsif ($slrThreadBuffer->tid == $slrThread8->tid) {
			$slrThread8->join();
		} elsif ($slrThreadBuffer->tid == $slrThread9->tid) {
			$slrThread9->join();
		} elsif ($slrThreadBuffer->tid == $slrThread10->tid) {
			$slrThread10->join();
		}
	}
}



# check for ithread support first
$Config{useithreads} or "Error:  You must recompile the Perl interpreter with thread support to run this program.\n";

# handle parameters passed by the user
decipherParameters();

# welcome the user (only in verbose mode)
if ($slrIsVerbose eq "true") {
	welcome();
}

# ask the preliminary question
prelimQuestions();

# stats for the user
$slrStartTime = `date`;
print "Beginning at...$slrStartTime";
print "Generating list...\n";
if ($slrIsTimelessSet ne "true") {
	appendFile($slrOutputFile, "Beginning at...$slrStartTime");
}

# create the list
createList();

# stats for the user
print "List generated...\n";
print "Finding available domains...\n";

# dig the list's domains
$slrBuffer = 0;
$slrBuffer2 = 0;
do {
	# initiate the next couple jobs
	queueJobs($slrBuffer);
	
	# wait for threads to finish
	joinJobs();
	
	# increment for next iteration
	$slrBuffer += 10;

	# end the program if we have reached the sequence for ending
	for ($slrBuffer2 = 0; $slrBuffer2 < 10; $slrBuffer2++) {
		if ($arrDomainList[($slrBuffer + $slrBuffer2)] eq $slrCustomEnd or scalar(@arrDomainList) <= ($slrBuffer + $slrBuffer2)) {
			$slrBuffer = "exit";
			last;
		}
	}
} while($slrBuffer ne "exit");

# stats for the user
$slrStopTime = `date`;
print "Completed at...$slrStopTime";
print "Ending...\n";
if ($slrIsTimelessSet ne "true") {
	appendFile($slrOutputFile, "Completed at...$slrStopTime");
}
