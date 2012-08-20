#!/usr/bin/perl

##########################################################################
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    This script was based on "blendbat.pl" by Stefano (S68) Selleri
#    which can be obtained at http://www.selleri.org/Blender/
#
##########################################################################

##############################################################
# A Perl Batch to spawn blender renderings                   #
##############################################################

####               PARAMETERS TO CONFIGURE                ####
@NodeNames   = ("machine_1", "machine_2", "machine_3");
#### The above parameter specifies the names of the machines (nodes)
#    onto which the rendering will be spawned.  More machines
#    can be added to suit your cluster.
#
$RootDir   = "directory_name";
#### The directory where the .blend file is and where the images
#    and logs will be store:
#    A directory is shared on one node and visible
#        by all other, in this directory a single copy of the .blend file
#        is stored and output.
#
#    The rendering will be produced independently, hence if you 
#    chosen AVI file you'll have as many AVIs as processes.
#    rendering TARGAs or JPGs and then using the sequence
#    editor can be better.
#
#    Console Outputs by Blender are redirected on a file, in
#    the RootDir directory, named dumpblend.N.M where N is the node
#    number (0,1,...) and M is the process number in that node,
#    usefull for debugging
#
$OutputDir   = "directory_name";
#### Directory where the rendered images will be placed.  If you are
#    using an NFS to share rendered images make sure this directory
#    exists on each node.
####                END OF CONFIG SECTION                 ####

$f = $ARGV[0] || die "Missing file name (try beowulf_blend.pl -h)\n";
if ($f=~/^-h/){
  print "\n\n  beowulf_blend.pl (C) Mar. 2008 Brandon (cdated) Fields\n\n";
  print "  based on blendbat.pl (C) Sept. 2002 Stefano (S68) Selleri\n\n";
  print "usage:\n\n     beowulf_blend.pl file.blend StartFrame EndFrame\n\n";
  print "  flile.blend - The blender file. it must be located in\n";
  print "                directory specified in the configuration parameters\n";
  print "                of this script.i\n\n";
  print "  StartFrame  - First frame of the batch\n";
  print "  EndFrame    - Last frame of the batch\n\n";
  die;
}
   
$start = $ARGV[1] || die "Missing start frame (try beowulf_blend.pl -h)\n";
$end = $ARGV[2] || die "Missing end frame (try beowulf_blend.pl -h)\n";

# Cleanup directory for new render
#`rm ./output/*.jpg *dump*`;

#$nf is number of frames
$nf=$end-$start; 

$finished = "false";

$i = $start;
for($start ... $end)
{
    $frames[$i] = $i;
    $rendered[$i] = "false";
    $nodeArray[$i] = "";
	$i++;
}

$i = $start;
foreach $node  (@NodeNames) 
{
	&renderFrame($i, $node);
	$nodeArray[$i] = $node;
	$i++;
}

#print "starting the while loop\n";

while ($finished eq "false")
{

	$frameNum = &nextRender();
	&checkRendered($frameNum);

	$i = $start;
	for ($start ... $end)
	{
		#print "Frame $i is $rendered[$i], and on node $nodeArray[$i]\n";
		$i++;
	}
	
	$finished = &allRendered();
}

sub checkNodes {
	my($node) = @_;

	$i = $start;
	for($start ... $end)
	{
    	if(($nodeArray[$i] = $node) && ($rendered[$i] eq "false"))
		{
			print "$node is currently busy\n";
			return "false";
		}
		else
		{
			return $node;
		}
		$i++;
	}
}

sub checkRendered {
	my ($frameNum) = @_;

	$i = $start;
	for($start ... $end)
	{
		$before = $rendered[$i];
    	if ($i < 10)
		{
			$rendered[$i] = &fileCheck("000$i.jpg");
		}
		elsif ($i < 100)
		{	
			$rendered[$i] = &fileCheck("00$i.jpg");
		}
		elsif ($i < 1000)
		{
			$rendered[$i] = &fileCheck("0$i.jpg");
		}
		else
		{
			$rendered[$i] = &fileCheck("$i.jpg");
		}
		#print "frame $i rendered is $rendered[$i]\n";
		$after = $rendered[$i];

		if (!($before eq $after))
		{
			print "frame $i has been rendered\n";
			print "the next frame is $frameNum\n";
			print "the node rendering it is $nodeArray[$i]\n";
			$nodeArray[$frameNum] = $nodeArray[$i];
			&renderFrame($frameNum, $nodeArray[$i]);
			#@rendered[$frameNum] = "active";
			return;
		}
		
		$i++;
	}
}

sub nextRender {
	$i = $start;
	for($start ... $end)
	{
		if (($nodeArray[$i] eq "") && ($rendered[$i] eq "false"))
    		{
        		print "The next frame to be rendered is $i\n";
			return $i;
    		}
    	$i++;
	}
}

sub allRendered {
	$i = $start;
	for($start ... $end)
	{
    	if ($rendered[$i] eq "false")
    	{
			return "false";
    	}
		$i++;
	}
	print "\nAll frames have been rendered!\n";
	return "true";
}

sub renderFrame {
	my($idx, $node) = @_;

	
    if(($nodeArray[$idx] == $node) && ($rendered[$idx] eq "false"))
	{
	print "The frame $idx is $rendered[$idx]\n";	
	print "node $node is currently rendering frame $idx\n";

	open RESULT, ">$node.txt";	
	print RESULT $idx;
	close RESULT;
	#`ssh -n $node "cd $RootDir ; blender -b $f -F JPEG -x 1 -s $idx -e $idx -a -x 1 > dumpblend.$idx; exit" &`;
	}
}

sub fileCheck {
	my ($file) = @_;

	if (-e "$OutputDir/$file") 
	{
		return "true";
	}
	else
	{
		return "false";
	}
}
