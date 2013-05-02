package MUSTdoSEO::DB;


use strict;
use lib '../';
use DBI;
use MUSTdoSEO::Functions qw(set_error);
use vars qw(@ISA);
@ISA = qw(MUSTdoSEO);

our $VERSION = sprintf "%d.%d", q$Revision: 1.1 $ =~ /(\d+)/g;


############
## NEW  ############
##############
##
## DESCRICAO: Construtor
##
## OPCOES:  new({database => 'teste',
##               hostname => 'localhost',
##               username => 'root',
##               password => '123456'})
## 
sub new
{
   my($class, $conf) = @_;
   my($dsn, $self, @dsn);
   
   if ($conf->{'db_cfg'} && open(CFG, "<$conf->{'db_cfg'}.cfg"))
   {
      foreach (<CFG>)
      {
         $conf->{'username'}    = $1 if (/^user\:\s+([^\s]+)/i);
         $conf->{'password'}    = $1 if (/^senha\:\s+([^\s]+)/i);
         $conf->{'driver_name'} = $1 if (/^dbserver\:\s+([^\s]+)/i);
         $conf->{'hostname'}    = $1 if (/^host\:\s+([^\s]+)/i);
      }
      close(CFG);
   }

   $self                    = {};
   $conf->{'driver_name'} ||= 'mysql';
   
   push @dsn, $conf->{'driver_name'}                      if ($conf->{'driver_name'});
   push @dsn, $conf->{'database'}                         if ($conf->{'database'});
   push @dsn, $conf->{'hostname'}                         if ($conf->{'hostname'});
   $conf->{'port'}   = ';port='.$conf->{'port'}           if ($conf->{'port'});
   $conf->{'socket'} = ';mysql_socket='.$conf->{'socket'} if ($conf->{'socket'});
   $dsn              = join(':', ('DBI', @dsn));
   $dsn             .= join('',$conf->{'port'},$conf->{'socket'}) if ($conf->{'port'} || $conf->{'socket'});
   
   bless ($self, $class);   
   
   $self->{'dsn'} = $dsn;
  
   if ($conf->{'database'})
   {
      if ($self->{'dbh'} = DBI->connect($dsn, $conf->{'username'}, $conf->{'password'}, {'mysql_enable_utf8' => 1}))
      {
         push @{$self->{'driver_names'}}, $_ foreach DBI->available_drivers;
         push @{$self->{'data_sources'}}, $_ foreach DBI->data_sources($conf->{'driver_name'});
      }
      else
      {
         $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, $DBI::errstr);
      }
   }
   else
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'Unknow database');
   }

   return $self;
}


###################
## DISCONNECT  #################
#######################
##
## DESCRICAO: Encerra conexao como BD
##
sub disconnect
{
   return shift->{'dbh'}->disconnect;
}



###################
## DBH  #################
#######################
##
## DESCRICAO: Retorna o handle do banco
##
sub dbh
{
   return shift->{'dbh'};
}


###################
## ERROR  #################
#######################
##
## DESCRICAO: Retorna mensagem de erro
##
sub error
{
   return shift->{'ERROR'};
}


###################
## STATS  #################
#######################
##
## DESCRICAO: Retorna mensagem de erro
##
sub stats
{
   return shift->{'STATS'};
}



1;

__END__
