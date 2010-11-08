#!/usr/bin/env pike
/* Author: Alwyn Malachi Berkeley
 * Created: 3-20-06
 * Description:  A simple application designed to utilize the dig program 
 * and a website in order to determine what 3 letter domain names are still
 * available for purchase.
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; only version 2 of the License.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 *      02111-1307, USA. */

import ADT;
import Protocols.HTTP;

enum bool { false, true };

void appendLine(string strFileName, string strLineToAppend) {
// This function appends a line to a file, it will throw an
// exception if the file cannot be opened

	Stdio.File OutputFile = Stdio.File();

	if (OutputFile->open(strFileName, "caw")) { // open file
		// write data
		if (OutputFile->write(strLineToAppend) == -1) {
			throw("Error #" + errno() + ": Couldn't write to " + strFileName + ".");
		}
	} else {
		throw("Error #" + errno() + ": Couldn't open " + strFileName + ".");
	}
	OutputFile->close(); // close file
}

bool checkDomainExtension(string strExtension) {
// This function checks if a string is a valid domain extension
// then returns true if it is, false if it isn't

	if (strlen(strExtension) != 0 && strExtension[0] == '.')
		return true;
	else
		return false;
}

bool checkEmailAddress(string strEmailParam) {
// This function checks to see if a email address is valid.
// It returns true if the address is valid and false if incorrect

	// check that there is only one "@" in the string
	if (String.count(strEmailParam, "@") != 1)
		return false;
	
	// check that there is only one "." in the string
	if (String.count(strEmailParam, ".") != 1)
		return false;

	// check that the "." comes after the "@"
	int intSpotOfAtSign = search(strEmailParam, "@", 0);
	int intSpotOfDotSign = search(strEmailParam, ".", 0);
	
	if (intSpotOfDotSign < intSpotOfAtSign)
		return false;
	
	return true;
}

bool checkSequence(string strSequence) {
// This function checks if a string is a valid 3-letter domain sequence
// then returns true if it is, false if it isn't

	if (strlen(strSequence) > 3) // no prefix or suffix as hyphen
		return false;
	else if (strSequence[0] == '-' || strSequence[2] == '-') // 3 letters
		return false;
	
	// cannot have letters aside from A-Z, a-z, or hyphen
	
	
	return true;
}

Queue createList(array(string) DomainExtensionsParam, string strStartSequenceParam, string strEndSequenceParam) {
// This function creates the list of domains that need to be checked, it
// returns a queue with the domains in it

	// create an array of letters a-z and 0-9
	array(string) LetterList = ({ });
	for (int x = 97; x < 123; x++)
		LetterList += ({ String.int2char(x) });
	
	for (int x = 48; x < 58; x++)
		LetterList += ({ String.int2char(x) });

	// generate every possible pattern
	array(string) DomainNameList = ({ });
	constant strPrefix = "www.";
	string strCurrentSequence;
	foreach (LetterList, string strFirstLetter) {
		foreach(LetterList + ({ "-" }), string strSecondLetter) {
			foreach(LetterList, string strThirdLetter) {
				foreach((array)DomainExtensionsParam, string strSuffix) {
					// prepare the current sequence
					strCurrentSequence = strPrefix + strFirstLetter + strSecondLetter + strThirdLetter + strSuffix;

					// add the current sequence to the queue
					DomainNameList += ({ strCurrentSequence});
				}
			}
		}
	}

	// finding where strStartSequenceParam is in the DomainNameList
	string strLastExtensionSuffix = DomainExtensionsParam[0];
	string strNeedle = strPrefix + strStartSequenceParam + strLastExtensionSuffix;
	int intStartIndex = search(DomainNameList, strNeedle);
	
	// finding where strEndSequenceParam is in the DomainNameList
	string strFirstExtensionSuffix = DomainExtensionsParam[sizeof(DomainExtensionsParam) - 1];
	strNeedle = strPrefix + strEndSequenceParam + strFirstExtensionSuffix;
	int intEndIndex = search(DomainNameList, strNeedle);

	// find the segment of the array that contains the values wanted
	array(string) PertinentDomainNames = DomainNameList[intStartIndex..intEndIndex];
	
	// convert the array segment that is left into a queue
	Queue DomainNameQueue = Queue();
	foreach (PertinentDomainNames, string strDomain)
		DomainNameQueue->write(strDomain);
	
	return DomainNameQueue;
}

mapping decipherParameters(array(string) ParameterVariable) {
// This function will decipher all the arguments sent to the program
// and return a mapping of the information sent
//
// NOTE: This function needs to ignore bad options somehow.
//constant INVALID_ARGUMENT = "Sorry, invalid argument, please try again ...\n";
// NOTE: This function also needs to support specifying the filename
mapping(string:string) ParameterInformation = ([ "extensions" : "no", "finish" : "no", "gui" : "no", "mail" : "no", "output" : "no", "start" : "no", "timeless" : "no", "verbose" : "no" ]);

	// parsing parameters
	array(array(array(string))) ArgumentDelimiters = ({
		({ "extensions", Getopt.HAS_ARG, ({ "-e", "--extensions" }) }),
		({ "finish", Getopt.HAS_ARG, ({ "-f", "--finish" }) }),
		({ "gui", Getopt.NO_ARG, ({ "-g", "--gui" }) }),
		({ "help", Getopt.NO_ARG, ({ "-h", "--help" }) }),
		({ "mail", Getopt.HAS_ARG, ({ "-m", "--mail" }) }),
		({ "output", Getopt.HAS_ARG, ({ "-o", "--output" }) }),
		({ "start", Getopt.HAS_ARG, ({ "-s", "--start" }) }),
		({ "timeless", Getopt.NO_ARG, ({ "-t", "--timeless" }) }),
		({ "verbose", Getopt.NO_ARG, ({ "-v", "--verbose" }) }),
		({ "version", Getopt.NO_ARG, ({ "-V", "--version" }) })
	});
	array(array(string)) Results;
	Results = Getopt.find_all_options(ParameterVariable, ArgumentDelimiters, true, 0);
	
	
	foreach (Results, array(string) ArgumentElement) {
		// show help and exit if needed
		if (ArgumentElement[0] == "help") {
			write ("Usage: fastfind [OPTION]... [FILE]...\n");
			write ("Find unregistered three letter domain names.\n\n");
			write ("-e, --extensions=[extension,...]   searches for only specified extensions.\n");
			write ("-f, --finish=[sequence]            ends the program at the sequence given.\n");
			write ("-g, --gui                          run the GUI version of the program.\n");
			write ("-h, --help                         displays the help dialog and then exits.\n");
			write ("-m, --mail=[recepient,server,port] emails the results to a particular address.\n");
			write ("-o, --output=[filename]            logs output in the file specified.\n");
			write ("-s, --start=[sequence]             starts the program at the sequence given.\n");
			write ("-t, --timeless                     report the output without the timestamps.\n");
			write ("-v, --verbose                      run program in verbose mode.\n");
			write ("-V, --version                      display version information and then exits.\n");
			write ("\nThe results are checked by two sources, so they are accurate most of the time.\n");
			write ("\nReport bugs to <malachix\@malachix.com>.\n");
			exit(0);
		}

		// show version if needed
		if (ArgumentElement[0] == "version") {
			write ("fastfind v0.2.0 alpha\n");
			write ("Written by Alwyn Malachi Berkeley.\n\n");
			write ("This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n");
			exit(0);
		}

		// tally the latest information to the mapping
		if (ArgumentElement[0] == "extensions")
			ParameterInformation["extensions"] = ArgumentElement[1];
		else if (ArgumentElement[0] == "finish")
			ParameterInformation["finish"] = ArgumentElement[1];
		else if (ArgumentElement[0] == "gui")
			ParameterInformation["gui"] = "yes";
		else if (ArgumentElement[0] == "mail")
			ParameterInformation["mail"] = ArgumentElement[1];
		else if (ArgumentElement[0] == "output")
			ParameterInformation["output"] = ArgumentElement[1];
		else if (ArgumentElement[0] == "start")
			ParameterInformation["start"] = ArgumentElement[1];
		else if (ArgumentElement[0] == "timeless")
			ParameterInformation["timeless"] = "yes";
		else if (ArgumentElement[0] == "verbose")
			ParameterInformation["verbose"] = "yes";
	}
		
	// return the mapping that contains the variables wanted in the program
	return ParameterInformation;
}

Queue digURLs(Queue DomainNamesParam, int intNumberToTest) {
// This function checks to see if a series of URLs are available by
// utilizing the "dig" utility
	
	// add the domains to a map
	int AmountOfDomainsLeft = sizeof((array)DomainNamesParam);
	mapping(string:string) Domain2Result = ([ ]);
	while (intNumberToTest-- > 0) {
		if (AmountOfDomainsLeft-- == 0) break;
		Domain2Result += ([ DomainNamesParam->read() : "" ]);
	}
	
	// find all the indices in the map
	array(string) MapIndices = indices(Domain2Result);

	// create the command that needs to be run
	string strCommand = "";
	foreach (MapIndices, string strMapIndex) {
		// add the dig command needed
		strCommand += "dig " + strMapIndex + " | grep 'HEADER'";

		// add the && to the command string if needed
		if (MapIndices[sizeof(MapIndices) - 1] != strMapIndex)
			strCommand += " && ";
	}

	// running the command && splitting the output into elements
	string strCommandResult = Process.popen(strCommand);
	array(string) CommandOutput = strCommandResult / "\n";
	
	// completing the mapping, each domain name corresponds with it's 
	// string output ex. "www.fhs.com" : ";; ->>HEADER<< ..." etc.
	int OutputIndex = 0;
	foreach (MapIndices, string strMapIndex) {
		// sometime a "" occurs in strMapIndex after the last
		// element, so this ensure the code does not error
		if (CommandOutput[OutputIndex] == "") break;

		// mapping domain
		Domain2Result[strMapIndex] = CommandOutput[OutputIndex];
		OutputIndex++;
	}
	
	// add all the domains that were non existent to the
	// AvailableNames queue
	Queue AvailableNames = Queue();
	foreach (MapIndices, string strMapIndex) {
		// tallies the domain if it exists
		if (search(Domain2Result[strMapIndex], "NXDOMAIN", 0) != -1)
			AvailableNames->write(strMapIndex);
	}

	return AvailableNames;
}

string readFile(string strFileName) {
// This function appends a line to a file, it will throw an
// exception if the file cannot be opened
//
// NOTE:  returns an empty string if the file could not be opened

	Stdio.File OutputFile = Stdio.File();
	string strData;
	
	if (OutputFile->open(strFileName, "r")) // open file
		strData = OutputFile->read(); // read in the data
	else
		return ""; // return nothing if file failed to open
	OutputFile->close(); // close file
		
	return strData;
}

void sendEmail(string strRecepientParam, string strServerParam, string strPortParam, string strMessage) {
// This function uses a perl-based program called "sendEmail" to send
// an email
//
// NOTE:  The program call "sendEmail" must be present on the system
// in order for this to work

	// create the command for sending the email(s)
	string strEmailCommand = "sendEmail -f DomainReport@DomainReport.com -t " + strRecepientParam + " -s " + strServerParam + ":" + strPortParam + " -u " + "'Three Letter Domains Report' -m \"" + strMessage + "\"";

	// run the command
	Process.system(strEmailCommand);
}

int surfURL(string strDomainNameParam) {
// This function checks to see if a URL is available by checking it
// with a whois tool hosted by http://www.whois-search.com
//
// NOTE:  THis function returns true if the domain exists was found
constant BASE_URL = "http://www.whois-search.com/whois/";
	
	// just leave the function if an empty string was the parameter
	if (strDomainNameParam == "") return 0;
	
	// get the source of the webpage that checks the domain
	string strCheckDomainURL = BASE_URL + strDomainNameParam; 
	Query WebpageResults;
	WebpageResults = get_url(strCheckDomainURL);
	
	// return true if the function found a match
	if (search(WebpageResults->data(), "No match", 0) == -1)
		return 1;

	return 0;
}

int main(int argc, array(string) argv) {
constant BEGIN_STATUS_MESSAGE = "Search beginning ...";
constant END_STATUS_MESSAGE = "Search ending ...";
Queue DomainNames = Queue();
Queue Results = Queue();
int intNumberOfDomainsFound = 0;
bool blnIsTimeless = false;
bool blnIsVerbose = false;
bool blnIsText = true; // notice, programs runs in text by default

	// decipher parameters
	mapping(string:string) Deciphered = decipherParameters(argv);
		
	// set the options wanted according to the arguments
	array(string) DomainExtensions = Deciphered["extensions"] / ",";
	string strEndSequence = Deciphered["finish"];
	if (Deciphered["gui"] == "yes") blnIsText = false;
	string strLogFile = Deciphered["output"];
	string strStartSequence = Deciphered["start"];
	if (Deciphered["timeless"] == "yes") blnIsTimeless = true;
	if (Deciphered["verbose"] == "yes") blnIsVerbose = true;
	
	array(string) MailBuffer = Deciphered["mail"] / ",";
	string strRecepient;
	string strServer;
	string strPort;
	if (MailBuffer[0] != "no") {
		strRecepient = MailBuffer[0];
		strServer = MailBuffer[1];
		strPort = MailBuffer[2];
	}
	
	
	if (blnIsText == true) { // text version
		constant strIncorrectValue = "Sorry, that is an incorrect value, please try again ...\n";

		// welcome the user
		write ("\tThis program is going to find all 3 letter domains still available for purchase and place the output in a file upon completion.\n\n");
		
		// ask for all pertinent data not supplied by arguments
		write ("Please answer the following question(s):\n");
		
		// ask for the domain extensions to use
		bool blnExitQuestion = false;
		string strResponse;
		if (DomainExtensions[0] == "no") {
			for (int x = 0; blnExitQuestion != true; x++) {
				// prompt
				if (x > 0) {
					write ("Type another extension to search for, or \"done\" if you finished:  ");
				} else {
					write ("Type a domain extension to search for (with the dot):  ");
				}
				strResponse = Stdio.stdin->gets();
			
				// lowercase just in case it wasn't before
				lower_case(strResponse);
			
				// evaluate response
				if (checkDomainExtension(strResponse) == true) {
					// the if statement makes sure the
					// correct values are added when there
					// were no arguments passed to the
					// program
					if (DomainExtensions[0] == "no")
						DomainExtensions = ({ strResponse });
					else
						DomainExtensions += ({ strResponse });
				} else if (strResponse == "done" && x > 0)
					blnExitQuestion = true;
				else
					write (strIncorrectValue);
			}
		}
		
		// ask which three letter sequence to start from
		if (strStartSequence == "no") {
			blnExitQuestion = false;
			do {
				// prompt
				write ("Type the sequence of characters to start from, ex. \"aaa\":  ");
				strResponse = Stdio.stdin->gets();
			
				// lowercase just in case it wasn't before
				lower_case(strResponse);

				// evaluate response
				if (checkSequence(strResponse) == true) {
					strStartSequence = strResponse;
					blnExitQuestion = true;		
				} else write (strIncorrectValue);
			} while(blnExitQuestion != true);
		}
		
		// ask which three letter sequence to end on
		if (strEndSequence == "no") {
			blnExitQuestion = false;
			do {
				// prompt
				write ("Type the sequence of characters to end on, ex. \"zzz\":  ");
				strResponse = Stdio.stdin->gets();
			
				// lowercase just in case it wasn't before
				lower_case(strResponse);

				// evaluate response
				if (checkSequence(strResponse) == true) {
					strEndSequence = strResponse;
					blnExitQuestion = true;		
				} else write (strIncorrectValue);
			} while(blnExitQuestion != true);
		}
		
		// ask for the output file name
		if (strLogFile == "no") {
			blnExitQuestion = false;
			do {
				// prompt
				write ("Type the filename for the log file (ex. logfile.txt):  ");
				strResponse = Stdio.stdin->gets();
			
				// lowercase just in case it wasn't before
				lower_case(strResponse);
			
				// evaluate response
				if (strlen(strResponse) > 0 ) {
					strLogFile = strResponse;
					blnExitQuestion = true;		
				} else write (strIncorrectValue);
			} while(blnExitQuestion != true);
		}
		
		if (MailBuffer[0] == "no") {
			// ask if the user wants the final report emailed to them
			blnExitQuestion = false;
			do {
				// prompt
				write ("Would you like the results emailed somewhere (type yes or no):  ");
				strResponse = Stdio.stdin->gets();
			
				// lowercase just in case it wasn't before
				lower_case(strResponse);
			
				// evaluate response
				if (strResponse == "yes" || strResponse == "no") {
					blnExitQuestion = true;		
				} else write (strIncorrectValue);
			} while(blnExitQuestion != true);

			if (strResponse == "yes") {
				// ask for the recepient email address
				blnExitQuestion = false;
				do {
					// prompt
					write ("Type receipient's email address, ex. \"guy@place.com\":  ");
					strResponse = Stdio.stdin->gets();
			
					// lowercase just in case it wasn't before
					lower_case(strResponse);

					// evaluate response
					if (checkEmailAddress(strResponse) == true) {
						strRecepient = strResponse;
						blnExitQuestion = true;		
					} else write (strIncorrectValue);
				} while(blnExitQuestion != true);

				// ask for the server
				blnExitQuestion = false;
				do {
					// prompt
					write ("Type the mail server to use (ex. mail.servername.com):  ");
					strResponse = Stdio.stdin->gets();
			
					// lowercase just in case it wasn't before
					lower_case(strResponse);
			
					// evaluate response
					if (strlen(strResponse) > 0 ) {
						strServer = strResponse;
						blnExitQuestion = true;	
					} else write (strIncorrectValue);
				} while(blnExitQuestion != true);
			
				// ask for the port to use
				blnExitQuestion = false;
				do {
					// prompt
					write ("Type remote port number to use (ex. 25):  ");
					strResponse = Stdio.stdin->gets();
			
					// lowercase just in case it wasn't before
					lower_case(strResponse);
			
					// evaluate response
					// NOTE:  Need to check that the input
					// was all numeric
					if (strlen(strResponse) > 0 ) {
						strPort = strResponse;
						blnExitQuestion = true;	
					} else write (strIncorrectValue);
				} while(blnExitQuestion != true);
			}
		}

		// send status messages
		string strCurrentTime;
		if (blnIsTimeless == false)
			strCurrentTime = ctime(time());
		else
			strCurrentTime = "\n";
		
		appendLine(strLogFile, BEGIN_STATUS_MESSAGE + strCurrentTime);
		write ("\n" + BEGIN_STATUS_MESSAGE + strCurrentTime);
		write ("Generating list of domain names to check...\n");
		
		// create list of domains to check
		DomainNames = createList(DomainExtensions, strStartSequence, strEndSequence);
	
		// send status messages
		write ("Finding available domain names...\n");

		// determine available domains
		string strDomain;
		while (DomainNames->is_empty() == 0) {
			// dig URLs to determine domain's availability
			Results = digURLs(DomainNames, 200);
		
			// update the number of domains found
			intNumberOfDomainsFound += sizeof((array)Results);

			// tally each non-existent domain
			while (Results->is_empty() == 0) {
				// double check those results first in order
				// to ensure accuracy, they must not already
				// exist
				strDomain = Results->read();
				if (surfURL(strDomain) == true) continue;
				
				// put it in the log file
				appendLine(strLogFile, strDomain + "\n");

				// tell user we found one if in verbose mode
				if (blnIsVerbose == true)
					write ("Found Domain:  " + strDomain + "\n");
			}
		}
		
		// send status messages
		if (blnIsTimeless == false)
			strCurrentTime = ctime(time());
		else
			strCurrentTime = "\n";

		appendLine(strLogFile, END_STATUS_MESSAGE + strCurrentTime);
		write (END_STATUS_MESSAGE + strCurrentTime);

		// send an automated mail to the user if needed
		if (strlen(strRecepient) > 0 && strlen(strServer) > 0 && strlen(strPort) > 0) {
			// read in the output file that was made
			string strMessage = readFile(strLogFile);
			
			// embed the output file into an email & send it
			sendEmail(strRecepient, strServer, strPort, strMessage);
		}
	} else { // GUI version

	}
	
return 0;
}
