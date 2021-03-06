#!/usr/bin/perl

#Rui Vilela 2007
#Gera um feed para o lançamento de novas versões do dicionário
#USAR com "makefile chuveiro-install"

use strict;
use warnings;
use XML::Atom::Feed;
use XML::Atom::Entry;
use Data::Dumper;
use Date::Format qw(time2str);
use encoding "utf-8";
use Encode "decode";
use File::Spec;
use File::Basename 'basename';
use Cwd 'getcwd';
use CGI 'escapeHTML';

#my $DIC='/home/ruivilela/t';
my $DIC='/home/natura/download/sources/Dictionaries';
my $url='http://natura.di.uminho.pt/download/sources/Dictionaries/';
#Assumir directoria da makefile
my $svn=File::Spec->catdir(getcwd, "DIC");

my $feedfile=File::Spec->catfile($DIC,'atom.xml');
#my $feedfile=File::Spec->catfile($DIC,'_atom.xml');

$XML::Atom::DefaultVersion = "1.0";

my $feed = XML::Atom::Feed->new(Version => 1.0);
my $data=time2str("%Y-%m-%dT%XZ",time);
my $data2=time2str("%Y%m%d",time);

$feed->title("Dicionários Opensource para o português");

my $mlink = XML::Atom::Link->new;
$mlink->type('text/html');
$mlink->rel('alternate');
$mlink->href('http://natura.di.uminho.pt/wiki/doku.php?id=dicionarios:main');
$feed->add_link($mlink);

my $author = XML::Atom::Person->new;
$author->name('Rui Vilela');
$author->email('ruivilela@di.uminho.pt');
$feed->author($author);

(my $currentRevision=`svn update | tail -n 1`)=~s/^\D*(\d+)\D*$/$1/;

$feed->id(time2str("%s",time)."-".$currentRevision);
$feed->updated($data);
#$feed->icon($url."dic.ico");

#######################################################

my $entry = XML::Atom::Entry->new(Version => 1.0);;

my $dd=File::Spec->catdir($DIC,'jspell');

my $ultRev=`ls -c1 $dd |grep -v 'latest' |grep -v 'bin' |sed -e 's/\.tar\.gz//' |sort |tail -n 2 |head -n 1`; ##eval?
chomp $ultRev;
#$ultData=$ultRev;
$ultRev=~s/\D*?(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
$ultRev.=" 00:01:00 -2300"; #Mesmo assim é apenas uma aproximação

my $l=time2str("%Y%m%d",time);

$entry->title("Nova versão do dicionário: jspell.pt-$l");

my $rsvn="<img src='http://natura.di.uminho.pt/download/sources/Dictionaries/eeng.png'/>";
$rsvn.="<h3>Departamento de Informática da Universidade do Minho</h3>";
$rsvn.="<h4>Projecto <a href='http://natura.di.uminho.pt/'>Natura</a> - Dicionários de português europeu (pt_PT)</h4>";
$rsvn.="<p>Disponíveis nos formatos: [";
$rsvn.=" <a href='$url$_/'>$_</a> |" for (qw/jspell myspell aspell aspell6 ispell hunspell/);
$rsvn=~s/\|$/\]/;
$rsvn.="</p>";
open my $F,"<$DIC/CHANGELOG" || warn $!;
my @LOG=<$F>;
$rsvn.="<p>-------- Última entrada do <a href='".$url."CHANGELOG'>CHANGELOG</a> -------</p><code>";
for (reverse @LOG){
    $rsvn.=escapeHTML($_); #Já em UTF8
    last if (/\d{2}:\d{2}:\d{2}/);
}
close $F;
$rsvn.='<p>'.("-"x40).'</p>';

my $lastUpdate=`svn log -r {\"$ultRev\"} |grep -e '^r' |awk '{print \$5,\$6}' `;
$rsvn.="<h4>Alterações efectuadas desde a última actualização(diff wordlist): $lastUpdate</h4>";
$rsvn.="<p><b>NOTA:</b> A possível sobregeração de formas verbais com pronomes clíticos é um problema conhecido, apenas afecta alguns dicionários.</p>";

$rsvn.="<code>";

#print "$verbdiffwordlist.pt_PT-$data2.txt";
open $F,"<verbdiffwordlist.pt_PT-$data2.txt" || warn $!;
while (<$F>){
    $rsvn.=escapeHTML(Encode::decode('iso-8859-1',$_));
}
close $F;
$rsvn.="</code>\n";

$rsvn.="<h4>Alterações efectuadas desde a última actualização(SVN): $lastUpdate</h4>";

$rsvn.="<code>";
foreach (`ls -1 $svn/*.dic`){
    $rsvn.= escapeHTML(Encode::decode('iso-8859-1',`cd $svn; svn diff -r {\"$ultRev\"}:$currentRevision --diff-cmd /usr/bin/diff -x -U1 $_`));

}
for (qw/irregulares.txt port.aff/){
    $rsvn.= escapeHTML(Encode::decode('iso-8859-1',`svn diff -r {\"$ultRev\"}:$currentRevision --diff-cmd /usr/bin/diff -x -U1 $_`));
}



$rsvn=~s/Index:.+\//<br\/><b>Ficheiro<\/b>: /g;
$rsvn=~s/Index: /<br\/><b>Ficheiro<\/b>: /g; #irregulares.txt
#$rsvn=~s!(---|\+\+\+).+?([^/]+\n)!$1$2!g;
$rsvn.="</code>\n";
$rsvn.="<p>Para mais informações consultar: <a href='http://natura.di.uminho.pt/wiki/doku.php?id=dicionarios:main'>Dicionários no Natura</a>.</p>\n";
$rsvn=~s/\n/<br\/>\n/g;

$entry->content($rsvn);

$entry->id(time2str("%s",time)."-".$currentRevision);
$entry->published($data);
$entry->updated($data);

$feed->add_entry($entry);

my $xml = $feed->as_xml;

######################################################

open $F, ">",$feedfile or warn "Não foi possível criar o ficheiro $feedfile - $!";
print $F $xml;
close $F;
print basename($feedfile)." criado com sucesso!\n" if (-e $feedfile);
