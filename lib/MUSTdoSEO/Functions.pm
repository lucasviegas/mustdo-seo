package MUSTdoSEO::Functions;

use strict;
use Exporter;
use warnings;
use vars qw(@ISA @EXPORT);
use Template;
use POSIX qw/strftime/;
use Crypt::Blowfish;
use Crypt::SaltedHash;
use Data::Dumper;


@ISA    = qw(Exporter);
@EXPORT = qw(encrypt_pass 
             decrypt_pass 
             check_access 
             encrypt_hex 
             decrypt_hex 
             process_template 
             set_error 
             get_date 
             trim 
             remove_accent 
             format_num);

my $session_time = 3600;

sub encrypt_pass
{
   my ($plain_pass) = @_;
   my ($csh);
      
   $csh = new Crypt::SaltedHash(algorithm => 'SHA-1');
   $csh->add($plain_pass);
   
   return $csh->generate;
}


sub decrypt_pass
{
   my ($encrypt_pass, $plain_pass) = @_;
   my ($csh);
      
   $csh = new Crypt::SaltedHash(algorithm => 'SHA-1');
   return $csh->validate($encrypt_pass, $plain_pass);
}


sub check_access
{
   my ($arg)= @_;
   my ($session);

   $session = $arg->{'cgi'}->cookie($arg->{'conf'}->{'session_name'});

   ## NAO EXISTE SESSAO
   if (!$session)
   {
      $arg->{'stat_msg'} = 'Invalid session! Try login again.';
      $arg->{'status'}   = 2;
   }
   
   ## VERIFICA A SESSAO
   else
   {
      $arg->{'controle'} = decrypt_hex($session);

      ## CERTIFICA QUE A CRYPTOGRAFIA NAO FOI ADULTERADA
      if (!$arg->{'control'}->{'time'} || !$arg->{'control'}->{'usu_id'} || !$arg->{'control'}->{'usu_login'})
      {
         $arg->{'stat_msg'} = 'Invalid session!';
         $arg->{'status'}   = 3;
      }
      
      ## VERIFICA TEMPO DA SESSAO
      elsif (($arg->{'control'}->{'time'} + ($arg->{'session_time'} || $session_time)) < time)
      {
         $arg->{'stat_msg'} = 'Session expired!';
         $arg->{'status'}   = 4;
      }
      
      ## SESSAO OK (RENOVADA)
      else
      {
         $arg->{'control'}->{'tempo'} = time;
         $arg->{'status'}              = 1;
      }
   }

   if ($arg->{'status'} != 1)
   {
#      $arg->{'pag'}    = '{"status":"'.$arg->{'status'}.'", "stat_msg":"'.$arg->{'stat_msg'}.'"}';
      $arg->{'session'} = $arg->{'cgi'}->cookie(-name => $arg->{'conf'}->{'session_name'}, -value => '', -expires => '-1d');
      return 0;
   }
   else
   {
#      $arg->{'pag'}    = '{"status":"1"}';
      $arg->{'session_expires'} = $arg->{'conf'}->{'session_time'} || 3600;
      $arg->{'session'} = $arg->{'cgi'}->cookie(-name => $arg->{'conf'}->{'session_name'}, -value => encrypt_hex($arg->{'control'}), -expires => '+'.$arg->{'session_expires'}.'s');
      return 1;
   }
}


=item * encrypt_hex

Usada para encriptar dados numa HASH. Retorna um resultado hexadecimal, sem 
caracteres especiais. Necessita da função C<dig> que gerar o dígito verificador.
A função inversa é a C<decrypt_hex> que realiza o procedimento inverso.

B<IMPORTANTE:> informe a referência do HASH;

   %data = (nome  => 'Nome sobrenome', 
             senha => 'teste123', 
             cod   => '124131');

   ($enc) = encrypt_hex(\%data);

   "$enc" vai ficar parecido com: 52616e646f6d49564dccda3d80b6a2f04b909b4b0847a35c0d3a
                                  72eabe29c4902a3ee0273b8471e5d407b84e58e960720b7c1d7a
                                  d1784c10699d9e37d226d9ba34

B<Obs.:> Dependendo da quantidade de dados a string de retorno vai ficar bem grande, 
mas o importante é que a criptografia usada nunca foi quebrada e é considerada 
muito boa.

=cut
sub encrypt_hex
{
   my($data, $key) = @_;
   my($cipher, $str_data, $encrypt, $chk, $d1, $d2);
 
   #Criptografa
   use Crypt::CBC;
   $cipher = Crypt::CBC->new(-cipher => 'Blowfish',
                             -key    => $key || 'khfKJHD984%Shfkjsk63HKdfakh&#5hld*Yd@@87kjkjha');
   
   $str_data = join("|", map { "$_:$data->{$_}" } keys %{$data});
   $encrypt = $chk = $cipher->encrypt_hex($str_data);
   
   #Gera digito verificador
   $chk =~ s/(.)/{hex($1)}/ge;
   $d1 .= dig($chk);
   $d2 .= dig($chk.$d1);

   return $encrypt.$d1.$d2;
}


=item * decrypt_hex

Usada para descriptografar a criptografia da função C<encrypt_hex>. Retorna uma 
referência para uma HASH com os dados originais remontados. Necessita da função C<dig> 
que gerar o dígito verificador.

   $enc  = '52616e646f6d49564dccda3d80b6a2f04b909b4b0847a35c0d3a'
   $enc .= '72eabe29c4902a3ee0273b8471e5d407b84e58e960720b7c1d7a'
   $enc .= 'd1784c10699d9e37d226d9ba34';

   ($data) = decrypt_hex($enc);

   $data = {
             'nome' => 'Nome sobrenome',
             'senha' => 'teste123',
             'cod' => '124131'
            };

B<Obs.:> Se a criptografia informada estiver corrompida ou fora do padrão a função não 
retornará nada. 

=cut
sub decrypt_hex
{
   my($crypt, $key) = @_;
   my($cipher, $str_data, $k, $v, $d1, $d2, $chk, %data, @dad);
   
   #Checa digito verificador
   ($crypt, $d1, $d2) = $crypt =~ /(.*)(.)(.)$/;
   $chk = $crypt.$d1;
   $chk =~ s/(.)/{hex($1)}/ge;
   if (dig($chk) == $d2)
   {
      $chk =~ s/(.)$//;
      return unless (dig($chk) == $d1);
   }
   else
   {
      return;
   }
   
   #Volta criptografia
   use Crypt::CBC;
   $cipher = Crypt::CBC->new(-cipher => 'Blowfish',
                             -key    => $key || 'khfKJHD984%Shfkjsk63HKdfakh&#5hld*Yd@@87kjkjha');
   eval { $str_data = $cipher->decrypt_hex($crypt); };
   @dad = split(/\|/, $str_data);
   map { ($k, $v) = split(/:/); $data{$k} = $v } @dad;
   
   return \%data;
}


=item * dig

Função usada para gerar dígito verificador. Recebe como entrada a numeração e 
retorna o dígito verificador.

   ($dig) = dig($str);

=cut
sub dig
{
   my ($str) = @_;
   my ($c, $t, $n, $dig);

   $c = 1;
   foreach $n (split //, $str)
   {
      $c  = 2 if ( ++$c > 9 );
      $t += ($n * $c);
   }
   $dig = (($t * 10) % 11);
   $dig = 1 if ($dig == 10);
   
   return $dig;
}


###################################################################
## PROCESS_TEMPLATE
###################################################################
#
#   &processa_template('path'       => '',      # diretorio onde estao os templates
#                      'template'   => '',      # nome do template que sera usado
#                      'dados'      => {},      # os dados que serao usados no template
#                      'ret_pagina' => \$var1,  # retorna o template processado
#                      'ret_error'   => \$var2); # referencia de scalar contendo o erro
#
###################################################################
sub process_template 
{
   my ($arg) = @_;
   my ($t, $input, $include_path, $vars, $output);
   
   $arg->{'data'}  ||= {};
   $input            = $arg->{'template'};
   $include_path     = $arg->{'conf'}->{'templ'}->{'path'};
   $vars             = {%{$arg->{'data'}}, 
                        'control'   => $arg->{'control'}, 
                        'functions' => $arg->{'conf'}->{'templ'}->{'functions'}, 
                        'pag'       => $arg->{'conf'}->{'pag'}, 
                        'conf'      => $arg->{'conf'}, 
                        'status'    => $arg->{'status'}, 
                        'stat_msg'  => $arg->{'stat_msg'}};

   $t = new Template(
#                      ABSOLUTE     => 1, 
#                      RELATIVE     => 1, 
                      INCLUDE_PATH => $include_path, # or list ref
                      INTERPOLATE  => 0,             # expand "$var" in plain text
                      POST_CHOMP   => 1,             # cleanup whitespace 
                      EVAL_PERL    => 1              # evaluate Perl code blocks
                    );

   unless ($t->process($input || 'index.html', $vars, \$output, binmode => ':utf8'))
   {
      $arg->{'stat_msg'} = set_erro(__FILE__, __LINE__, $t->error->type().'|'.$t->error->info());
      $arg->{'status'}   = 10;
      return 0;
   }
   $arg->{'pag'} = $output || $arg->{'ret_error'};
#   utf8::encode($arg->{'pag'});

   return 1;
}


sub set_error 
{
   my ($file, $linha, $msg) = @_;
   $msg =~ s/\n|\r/ /g;
   $msg = &get_date().'|ERRO|'.$file.'|'.$linha.'|'.$msg;
#   print STDERR $msg;
   return $msg;
}


sub get_date 
{ 
   return strftime (($_[0] || '%Y-%m-%d %H:%M:%S'), localtime($_[1] || time));
} 


sub trim 
{
   my ($str) = @_;
   $str =~ s/^\s+|\s+$//g;
   return $str;
}


sub remove_accent
{
   my ($str) = @_;
#   $str =~ tr/áéíóúÁÉÍÓÚàèÀÈãõAÕâêôÂÊÔçC/aeiouAEIOUaeAEaoAOaeoAEOcC/;
   $str =~ tr/\xE1\xE9\xED\xF3\xFA\xC1\xC9\xCD\xD3\xDA\xE0\xE8\xC0\xC8\xE3\xF5\xC3\xD5\xE2\xEA\xF4\xC2\xCA\xD4\xE7\xC7/aeiouAEIOUaeAEaoAOaeoAEOcC/;
   return $str;
}


sub format_num
{
   my ($str) = $_[0] || '';
   while ($str=~s/(\d)(\d\d\d)(?!\d)/$1.$2/){}
   return $str;
}


1;

__END__

