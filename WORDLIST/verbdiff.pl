#!/usr/bin/perl -l -w

while(<>){
    chomp;
    push @i,$_ if /^>/;
    push @o,$_ if /^</;
}

#print "Diferen�as de palavras desde a �ltima vers�o (FALTA ID DA VERS�O ANTERIOR)"; 
print "\n\n**Removidas**"; 
map {print} @o; 
print "\n\n**Adicionadas**"; 
map {print} @i;

# rawdiffwordlist.$L-`$(DATE)`.txt > verbdiffwordlist.$L-`$(DATE)`.txt
